// @ts-nocheck
const _ = require('lodash');

const DetoxRuntimeError = require('../../../../errors/DetoxRuntimeError');
const detectConcurrentDetox = require('../../../../utils/detectConcurrentDetox');
const log = require('../../../../utils/logger').child({ cat: 'device' });
const IosSimulatorCookie = require('../../../cookies/IosSimulatorCookie');
const AllocationDriverBase = require('../AllocationDriverBase');

const SimulatorQuery = require('./SimulatorQuery');

class SimulatorAllocDriver extends AllocationDriverBase {
  /**
   * @param deviceRegistry { DeviceRegistry }
   * @param detoxConfig { DetoxInternals.RuntimeConfig }
   * @param deviceRegistry { DeviceRegistry }
   * @param applesimutils { AppleSimUtils }
   * @param simulatorLauncher { SimulatorLauncher }
   */
  constructor({ detoxConfig, deviceRegistry, applesimutils, simulatorLauncher }) {
    super();
    this._deviceRegistry = deviceRegistry;
    this._applesimutils = applesimutils;
    this._simulatorLauncher = simulatorLauncher;
    this._launchInfo = {};
    this._shouldShutdown = detoxConfig.behavior.cleanup.shutdownDevice;
  }

  async init() {
    if (!detectConcurrentDetox()) {
      await this._deviceRegistry.reset();
    }
  }

  /**
   * @param deviceConfig { Object }
   * @return {Promise<IosSimulatorCookie>}
   */
  async allocate(deviceConfig) {
    const deviceQuery = new SimulatorQuery(deviceConfig.device);

    // TODO Delegate this onto a well tested allocator class
    const udid = await this._deviceRegistry.registerDevice(async () => {
      return await this._findOrCreateDevice(deviceQuery);
    });

    if (!udid) {
      throw new DetoxRuntimeError(`Failed to find device matching ${deviceQuery.getDeviceComment()}`);
    }

    this._launchInfo[udid] = { deviceConfig };
    return new IosSimulatorCookie(udid);
  }

  /**
   * @param {IosSimulatorCookie} deviceCookie
   * @returns {Promise<void>}
   */
  async postAllocate(deviceCookie) {
    const { udid } = deviceCookie;
    const { deviceConfig } = this._launchInfo[udid];
    await this._simulatorLauncher.launch(udid, deviceConfig.type, deviceConfig.bootArgs, deviceConfig.headless);
  }

  /**
   * @param cookie { IosSimulatorCookie }
   * @param options { DeallocOptions }
   * @return {Promise<void>}
   */
  async free(cookie, options = {}) {
    const { udid } = cookie;

    if (options.shutdown) {
      await this._doShutdown(udid);
      await this._deviceRegistry.unregisterDevice(udid);
    } else {
      await this._deviceRegistry.releaseDevice(udid);
    }
  }

  async cleanup() {
    if (this._shouldShutdown) {
      const sessionDevices = await this._deviceRegistry.readSessionDevices();
      const shutdownPromises = sessionDevices.getIds().map((udid) => this._doShutdown(udid));
      await Promise.all(shutdownPromises);
    }

    await this._deviceRegistry.unregisterSessionDevices();
  }

  /**
   * @param {string} udid
   * @returns {Promise<void>}
   * @private
   */
  async _doShutdown(udid) {
    try {
      await this._simulatorLauncher.shutdown(udid);
    } catch (err) {
      log.warn({ event: 'DEVICE_ALLOCATOR', err }, `Failed to shutdown simulator ${udid}`);
    }
  }

  /***
   * @private
   * @param {SimulatorQuery} deviceQuery
   * @returns {Promise<String>}
   */
  async _findOrCreateDevice(deviceQuery) {
    let udid;

    const { free, taken } = await this._groupDevicesByStatus(deviceQuery);

    if (_.isEmpty(free)) {
      const prototypeDevice = taken[0];
      udid = this._applesimutils.create(prototypeDevice);
      await this._runScreenshotWorkaround(udid);
    } else {
      udid = free[0].udid;
    }

    this._allocatedSimulators.add(udid);
    return udid;
  }

  async _runScreenshotWorkaround(udid) {
    await this._applesimutils.takeScreenshot(udid, '/dev/null').catch(() => {
      log.debug({}, `
          NOTE: For an unknown yet reason, taking the first screenshot is apt
          to fail when booting iOS Simulator in a hidden window mode (or on CI).
          Detox applies a workaround by taking a dummy screenshot to ensure
          that the future ones are going to work fine. This screenshot is not
          saved anywhere, and the error above is suppressed for all log levels
          except for "debug" and "trace."
        `.trim());
    });
  }

  /**
   * @private
   * @param {SimulatorQuery} deviceQuery
   */
  async _groupDevicesByStatus(deviceQuery) {
    const searchResults = await this._queryDevices(deviceQuery);
    const takenDevices = this._deviceRegistry.getTakenDevicesSync();

    const { taken, free }  = _.groupBy(searchResults, ({ udid }) => {
      return takenDevices.includes(udid) ? 'taken' : 'free';
    });

    const targetOS = _.get(taken, '0.os.identifier');
    const isMatching = targetOS && { os: { identifier: targetOS } };

    return {
      taken: _.filter(taken, isMatching),
      free: _.filter(free, isMatching),
    };
  }

  /**
   * @private
   * @param {SimulatorQuery} deviceQuery
   */
  async _queryDevices(deviceQuery) {
    const result = await this._applesimutils.list(
      deviceQuery,
      `Searching for device ${deviceQuery} ...`
    );

    if (_.isEmpty(result)) {
      throw new DetoxRuntimeError({
        message: `Failed to find a device ${deviceQuery}`,
        hint: `Run 'applesimutils --list' to list your supported devices. ` +
          `It is advised only to specify a device type, e.g., "iPhone Xʀ" and avoid explicit search by OS version.`
      });
    }
    return result;
  }
}

module.exports = SimulatorAllocDriver;
