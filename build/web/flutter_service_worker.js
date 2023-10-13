'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "shared-buffer-worklet-processor.js": "19722a3bc899caf9b933d91ef721b5b6",
"signal.worker.js": "9c84b0d34e9bda488b1f92671f337160",
"file.worker.js": "d3b3022f0a4266f2a5095f83e5b77d37",
"version.json": "68822ce4ee0133d71e639d80bb94a3c7",
"a.out.wasm": "9da46485bc73cf80fc15cf573d22a326",
"favicon.ico": "5547ebb1f9e482bdb8501f4f1afc89aa",
"sr_icon.png": "e89ce37d1d62f8d5c92a95c653cfabe9",
"index.html": "00b291da01a09973eec9a707eed7a30d",
"/": "00b291da01a09973eec9a707eed7a30d",
"shared-buffer-worklet-node.js": "bc54f860c9f22be781e48acb3970fec3",
"___version.json": "8981d1836c3b5f957af753cecdf11b0c",
"signalprocessing.js": "a463e6affdc10ee9e548aede1b1e728a",
"serial.worker.js": "e2476ffc91f37c4b379addf046e0e5d5",
"byb-logo.png": "935c4a4be9383fa6a0d5b5d98d64bda5",
"jszip.min.js": "41e1c35ed92e3a20bb6a2cf090b48112",
"main.dart.js": "99712cbb84ba5e401de1d87bcee0011f",
"playback.sequential.signal.worker.js": "e5ad934383a82cfae134dfa9ee3f5760",
"shared-buffer-worker.js": "31ba08100d5147222926c01db524e926",
"sequential.signal.worker.js": "39ef415400fa95e6e5b66c6ad0b8ba13",
"playback.signal.worker.js": "745ae7c1d1016427659987a8b2facfa9",
"signalprocessing.wasm": "f8e393f4692806eb1d93c3d891b3f1dc",
"bundle.js": "02a2b416e13ca4ce78978f24a921e8ee",
"wasm.worker.js": "b92b215a51cdd68809c343f7405ac2e8",
"wavefile.js": "e17de4cd46f8a244d594c709fe3315f5",
"flutter.js": "0816e65a103ba8ba51b174eeeeb2cb67",
"index.js": "72dbd00c281cdab75691ddf2f7ce109e",
"sequential.file.worker.js": "6fd8e2212c4370afc08c322c81574e2c",
"playback-sequential-shared-buffer-worker.js": "15327609fe7f410d5de2f940c069ab25",
"readwavfile.worker.js": "360f79255feee55c3e77bfdedf736709",
"OldWasmWorker.js": "970fce779749fe3bb875217be669e180",
"favicon.png": "5547ebb1f9e482bdb8501f4f1afc89aa",
"playback-sequential-shared-buffer-worklet-processor.js": "bd76870665a0d0be76aeca27ceb8e515",
"canvaskit.js": "c2b4e5f3d7a3d82aed024e7249a78487",
"myindex.js": "72dbd00c281cdab75691ddf2f7ce109e",
"icons/Icon-192.png": "d745387173eb3f98a0966da6a0830aba",
"icons/Icon-maskable-192.png": "d745387173eb3f98a0966da6a0830aba",
"icons/Icon-maskable-512.png": "e238415e3e1597c6f9a51924db4d753b",
"icons/Icon-512.png": "e238415e3e1597c6f9a51924db4d753b",
"manifest.json": "abbc5c526d6562acf9af56e5c968b51a",
"sequential-shared-buffer-worker-processor.js": "bba1b1e12bcfe071a3630f512f7dfa59",
"sequential-shared-buffer-worker.js": "98a44fb60055612e257102ad812af2ca",
"playback-shared-buffer-worklet-processor.js": "7b2ee076c095f6d01019d6bb9065d61f",
"wavefileparser.js": "2e71e47b47760261bf9f59aaa94e861b",
"playback-sequential-shared-buffer-worker-node.js": "b17f080918ed1985cad8143f13273dd0",
"assets/AssetManifest.json": "1ce75482e0e44909d779c07e9f9d0e84",
"assets/NOTICES": "43d6d2552b3c80352363dcd1ece93218",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "6d342eb68f170c97609e9da345464e5e",
"assets/packages/fialogs/assets/empty.png": "95fea0110ac9fb09c2c68b37213364fe",
"assets/fonts/MaterialIcons-Regular.otf": "95db9098c58fd6db106f1116bae85a0b",
"assets/assets/sr_icon.png": "c683608920080512c9e573312fa1ae57",
"assets/assets/libopus.js": "e054d268a49a490e2cbd633d32c2f9ec",
"assets/assets/libopus.wasm": "3fa83e8321ab08a73c3a33e2c30f89ab",
"oldindex.html": "4013d20bbb32b28f9da30d0fe746f956",
"_ori_file.worker.js": "6abc174734fa77955bacb0332c6efef8",
"a.out.js": "ec99537be7d21d4c93e5a530d525fbea",
"index%20copy.html": "4cf7fbb5f85e6a8168e60cc13c2b2572",
"sequential-shared-buffer-worker-node.js": "2d05f8aa6e588fbb6ec3470131bd9f19",
"jszip.js": "73774af2765630e4df17f9b00b4698bf",
"canvaskit/canvaskit.js": "c2b4e5f3d7a3d82aed024e7249a78487",
"canvaskit/profiling/canvaskit.js": "ae2949af4efc61d28a4a80fffa1db900",
"canvaskit/profiling/canvaskit.wasm": "95e736ab31147d1b2c7b25f11d4c32cd",
"canvaskit/canvaskit.wasm": "4b83d89d9fecbea8ca46f2f760c5a9ba"
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "main.dart.js",
"index.html",
"assets/NOTICES",
"assets/AssetManifest.json",
"assets/FontManifest.json"];
// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});

// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});

// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache.
        return response || fetch(event.request).then((response) => {
          cache.put(event.request, response.clone());
          return response;
        });
      })
    })
  );
});

self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});

// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}

// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
