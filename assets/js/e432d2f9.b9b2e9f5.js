"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[8928],{3905:(e,t,n)=>{n.d(t,{Zo:()=>c,kt:()=>h});var i=n(7294);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function o(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);t&&(i=i.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,i)}return n}function s(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?o(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):o(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function r(e,t){if(null==e)return{};var n,i,a=function(e,t){if(null==e)return{};var n,i,a={},o=Object.keys(e);for(i=0;i<o.length;i++)n=o[i],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(i=0;i<o.length;i++)n=o[i],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var l=i.createContext({}),u=function(e){var t=i.useContext(l),n=t;return e&&(n="function"==typeof e?e(t):s(s({},t),e)),n},c=function(e){var t=u(e.components);return i.createElement(l.Provider,{value:t},e.children)},p={inlineCode:"code",wrapper:function(e){var t=e.children;return i.createElement(i.Fragment,{},t)}},d=i.forwardRef((function(e,t){var n=e.components,a=e.mdxType,o=e.originalType,l=e.parentName,c=r(e,["components","mdxType","originalType","parentName"]),d=u(n),h=a,m=d["".concat(l,".").concat(h)]||d[h]||p[h]||o;return n?i.createElement(m,s(s({ref:t},c),{},{components:n})):i.createElement(m,s({ref:t},c))}));function h(e,t){var n=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var o=n.length,s=new Array(o);s[0]=d;var r={};for(var l in t)hasOwnProperty.call(t,l)&&(r[l]=t[l]);r.originalType=e,r.mdxType="string"==typeof e?e:a,s[1]=r;for(var u=2;u<o;u++)s[u]=n[u];return i.createElement.apply(null,s)}return i.createElement.apply(null,n)}d.displayName="MDXCreateElement"},3182:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>l,contentTitle:()=>s,default:()=>p,frontMatter:()=>o,metadata:()=>r,toc:()=>u});var i=n(7462),a=(n(7294),n(3905));const o={id:"flakiness",slug:"troubleshooting/flakiness",title:"Dealing With Flakiness in Tests",sidebar_label:"Dealing With Flakiness in Tests"},s=void 0,r={unversionedId:"flakiness",id:"version-19.x/flakiness",title:"Dealing With Flakiness in Tests",description:"Dealing With Flakiness in Tests",source:"@site/versioned_docs/version-19.x/Troubleshooting.Flakiness.md",sourceDirName:".",slug:"/troubleshooting/flakiness",permalink:"/Detox/docs/troubleshooting/flakiness",draft:!1,editUrl:"https://github.com/wix/Detox/edit/next/docs/versioned_docs/version-19.x/Troubleshooting.Flakiness.md",tags:[],version:"19.x",frontMatter:{id:"flakiness",slug:"troubleshooting/flakiness",title:"Dealing With Flakiness in Tests",sidebar_label:"Dealing With Flakiness in Tests"},sidebar:"tutorialSidebar",previous:{title:"Dealing With Synchronization Issues in Tests",permalink:"/Detox/docs/troubleshooting/synchronization"},next:{title:"Running Locally",permalink:"/Detox/docs/guide/running-locally"}},l={},u=[{value:"Dealing With Flakiness in Tests",id:"dealing-with-flakiness-in-tests",level:2},{value:"1. We Feel Your Pain",id:"1-we-feel-your-pain",level:3},{value:"2. Sources of Flakiness",id:"2-sources-of-flakiness",level:3},{value:"3. Get More Data About the Problem",id:"3-get-more-data-about-the-problem",level:3}],c={toc:u};function p(e){let{components:t,...n}=e;return(0,a.kt)("wrapper",(0,i.Z)({},c,n,{components:t,mdxType:"MDXLayout"}),(0,a.kt)("h2",{id:"dealing-with-flakiness-in-tests"},"Dealing With Flakiness in Tests"),(0,a.kt)("blockquote",null,(0,a.kt)("p",{parentName:"blockquote"},"What is a flaky test?")),(0,a.kt)("p",null,"A flaky test is a test that passes most of the time, and sometimes without any apparent reason and without any changes to your app - it fails. This can even happen only on certain machines. For example, on your own machine it always passes, but on a different slower machine, like the CI, it fails."),(0,a.kt)("h3",{id:"1-we-feel-your-pain"},"1. We Feel Your Pain"),(0,a.kt)("p",null,"Flakiness is the greatest challenge in E2E. The good news is that Detox was designed with this mission in mind: dealing with flakiness head on."),(0,a.kt)("p",null,"Assume you have a suite of 100 tests and each test is flaky in 0.5% of executions (failing without an actual bug in your app). The total flakiness of your entire suite is about 40% (the exact formula is ",(0,a.kt)("inlineCode",{parentName:"p"},"1 - (1 - 0.005)^100"),"). This means that there\u2019s 40% chance your suite will fail without an actual bug! This makes your entire suite useless."),(0,a.kt)("h3",{id:"2-sources-of-flakiness"},"2. Sources of Flakiness"),(0,a.kt)("p",null,"It\u2019s important to identify the various sources of flakiness in Detox tests."),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("p",{parentName:"li"},"Control of the device / simulator - in order to run your tests, Detox must communicate with a simulator and instruct it to install the app, restart it, etc. Simulators don\u2019t always behave and controlling them might occasionally fail. Detox\u2019s underlying simulator control is ",(0,a.kt)("a",{parentName:"p",href:"https://github.com/wix/AppleSimulatorUtils"},(0,a.kt)("inlineCode",{parentName:"a"},"AppleSimulatorUtils")),', it is a tool that supports both basic and advanced simulator and device interaction options, it uses some core simulator features which are not always stable and may need time to "warm up" (booting, shutting down, etc.). Detox is set to have a few retries on any of these actions before failing. It will also print all the ',(0,a.kt)("inlineCode",{parentName:"p"},"exec")," commands when using ",(0,a.kt)("inlineCode",{parentName:"p"},"verbose")," log level, and with ",(0,a.kt)("inlineCode",{parentName:"p"},"trace")," level it will print everything.")),(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("p",{parentName:"li"},"Asynchronous operations inside your app - every time an E2E test runs, operations might take place in a different order inside your app. This makes E2E tests nondeterministic. Consider an HTTP request made to a server, this request may take a variable time to complete due to external concerns like network congestion and server load. Detox takes this into account by monitoring all asynchronous operations that take place in your app from the inside. Detox knows which network requests are currently in-flight. Detox knows how busy the React Native bridge is. Tests are automatically synchronized to the app and only move forward when the app is idle."))),(0,a.kt)("h3",{id:"3-get-more-data-about-the-problem"},"3. Get More Data About the Problem"),(0,a.kt)("p",null,"In order to identify the source of flakiness you\u2019re suffering from you need more data. If you catch a failing test that should be passing, you need to record as much information as possible in order to investigate."),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Enable ",(0,a.kt)("inlineCode",{parentName:"li"},"trace")," mode in Detox. This will output a lot of information about what happening during the test:",(0,a.kt)("ol",{parentName:"li"},(0,a.kt)("li",{parentName:"ol"},(0,a.kt)("inlineCode",{parentName:"li"},"exec")," commands"),(0,a.kt)("li",{parentName:"ol"},"All communication going over the websocket, both from tester and app")))),(0,a.kt)("p",null,"To enable ",(0,a.kt)("inlineCode",{parentName:"p"},"trace")," mode run your tests in trace log mode:"),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-sh"},"detox test --loglevel trace\n")))}p.isMDXComponent=!0}}]);