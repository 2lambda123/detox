const cp = require('child_process');

const _ = require('lodash');
const parser = require('yargs-parser');
const unparse = require('yargs-unparser');

const detox = require('../../internals');
const log = detox.log.child({ cat: ['lifecycle', 'cli'] });
const { DetoxRuntimeError } = require('../../src/errors');
const { printEnvironmentVariables, prependNodeModulesBinToPATH } = require('../../src/utils/envUtils');
const { escapeSpaces } = require('../../src/utils/shellUtils');

class TestRunnerCommand {
  constructor() {
    this._argv = {};
    this._cli2env = {};
    this._envHint = {};
    this._envFwd = {};
    this._retries = 0;
    /** @type {Detox.DetoxDeviceConfig} */
    this._deviceConfig = null;
  }

  /**
   * @param {Partial<Readonly<DetoxInternals.CLIConfig>>} cliConfig
   * @returns {this}
   */
  replicateCLIConfig(cliConfig) {
    this._cli2env = _.omitBy({
      DETOX_APP_LAUNCH_ARGS: cliConfig.appLaunchArgs,
      DETOX_ARTIFACTS_LOCATION: cliConfig.artifactsLocation,
      DETOX_CAPTURE_VIEW_HIERARCHY: cliConfig.captureViewHierarchy,
      DETOX_CLEANUP: cliConfig.cleanup,
      DETOX_CONFIGURATION: cliConfig.configuration,
      DETOX_CONFIG_PATH: cliConfig.configPath,
      DETOX_DEBUG_SYNCHRONIZATION: cliConfig.debugSynchronization,
      DETOX_DEVICE_BOOT_ARGS: cliConfig.deviceBootArgs,
      DETOX_DEVICE_NAME: cliConfig.deviceName,
      DETOX_FORCE_ADB_INSTALL: this._deviceConfig.type.startsWith('android.')
        ? cliConfig.forceAdbInstall
        : undefined,
      DETOX_GPU: cliConfig.gpu,
      DETOX_HEADLESS: cliConfig.headless,
      DETOX_KEEP_LOCKFILE: cliConfig.keepLockFile,
      DETOX_LOGLEVEL: cliConfig.loglevel,
      DETOX_READ_ONLY_EMU: cliConfig.readonlyEmu,
      DETOX_RECORD_LOGS: cliConfig.recordLogs,
      DETOX_RECORD_PERFORMANCE: cliConfig.recordPerformance,
      DETOX_RECORD_VIDEOS: cliConfig.recordVideos,
      DETOX_REPORT_SPECS: cliConfig.jestReportSpecs,
      DETOX_RETRIES: cliConfig.retries,
      DETOX_REUSE: cliConfig.reuse,
      DETOX_TAKE_SCREENSHOTS: cliConfig.takeScreenshots,
      DETOX_USE_CUSTOM_LOGGER: cliConfig.useCustomLogger,
    }, _.isUndefined);

    this._envHint = _(process.env)
      .mapKeys((_value, key) => key.toUpperCase())
      .pickBy((_value, key) => key.startsWith('DETOX_'))
      .omit(['DETOX_CONFIG_SNAPSHOT_PATH'])
      .value();

    return this;
  }

  /**
   * @param {Detox.DetoxDeviceConfig} config
   * @returns {this}
   */
  setDeviceConfig(config) {
    this._deviceConfig = config;

    return this;
  }

  /**
   * @param {Detox.DetoxTestRunnerConfig} config
   * @returns {this}
   */
  setRunnerConfig(config) {
    this._argv = config.args;
    this._retries = config.inspectBrk ? 0 : config.retries;
    if (config.forwardEnv) {
      this._envFwd = this._cli2env;
      Object.assign(this._envHint, this._cli2env);
    }

    return this;
  }

  async execute() {
    let runsLeft = 1 + this._retries;
    let launchError;

    do {
      try {
        if (launchError) {
          const list = this._argv._.map((file, index) => `  ${index + 1}. ${file}`).join('\n');
          log.error(
            `There were failing tests in the following files:\n${list}\n\n` +
            'Detox CLI is going to restart the test runner with those files...\n'
          );
        }

        await this._doExecute();
        launchError = null;
      } catch (e) {
        launchError = e;

        const failedTestFiles = detox.session.testResults.filter(r => !r.success);

        const { bail } = detox.config.testRunner;
        if (bail && failedTestFiles.some(r => r.isPermanentFailure)) {
          throw e;
        }

        const testFilesToRetry = failedTestFiles.filter(r => !r.isPermanentFailure).map(r => r.testFilePath);
        if (_.isEmpty(testFilesToRetry)) {
          throw e;
        }

        if (--runsLeft > 0) {
          this._argv._ = testFilesToRetry;
          // @ts-ignore
          detox.session.testSessionIndex++; // it is always a primary context, so we can update it
        }
      }
    } while (launchError && runsLeft > 0);

    if (launchError) {
      throw launchError;
    }
  }

  async _doExecute() {
    const fullCommand = this._buildSpawnArguments().map(escapeSpaces);
    const fullCommandWithHint = printEnvironmentVariables(this._envHint) + fullCommand.join(' ');

    log.info({ env: this._envHint }, fullCommandWithHint);

    return new Promise((resolve, reject) => {
      cp.spawn(fullCommand[0], fullCommand.slice(1), {
        shell: true,
        stdio: 'inherit',
        env: _({})
          .assign(process.env)
          .assign(this._envFwd)
          .omitBy(_.isUndefined)
          .tap(prependNodeModulesBinToPATH)
          .value()
      })
        .on('error', (err) => reject(err))
        .on('exit', (code) => code === 0
          ? resolve()
          : reject(new DetoxRuntimeError(`Command failed with exit code = ${code}:\n${fullCommandWithHint}`)
        ));
    });
  }

  _buildSpawnArguments() {
    const { _: specs = [], '--': passthrough = [], $0, ...argv } = this._argv;
    const { _: $0_, ...$0argv } = parser($0);

    return [
      ...$0_,
      ...unparse($0argv),
      ...unparse(argv),
      ...unparse({ _: [...passthrough, ...specs] }),
    ].map(String);
  }
}

module.exports = TestRunnerCommand;