'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "shared-buffer-worklet-processor.js": "52e675267c7e93edadd16a8446423e73",
"signal.worker.js": "97962a64dfd54f5d2e72e0a6444f00ca",
"file.worker.js": "89272d746d4e59aae9a62a658a40b3db",
"version.json": "8981d1836c3b5f957af753cecdf11b0c",
"a.out.wasm": "9da46485bc73cf80fc15cf573d22a326",
"index.html": "2c7cfd894407acfd20623726de8cf3b5",
"/": "2c7cfd894407acfd20623726de8cf3b5",
"shared-buffer-worklet-node.js": "6a854cb469a311ed281e685c8d271528",
"signalprocessing.js": "a463e6affdc10ee9e548aede1b1e728a",
"main.dart%20copy.js": "82bb7f5b671e5c4824c987ccc2798e16",
"serial.worker.js": "e2476ffc91f37c4b379addf046e0e5d5",
"main.dart.js": "b412daae5b157d24bc799ca54c44c03e",
"shared-buffer-worker.js": "2c80348d6e8a18c8f9cc985254049a0e",
"sequential.signal.worker.js": "df73a0caa97f8f9c15b8b5dc88ef4839",
"signalprocessing.wasm": "f8e393f4692806eb1d93c3d891b3f1dc",
"bundle.js": "02a2b416e13ca4ce78978f24a921e8ee",
"wasm.worker.js": "b92b215a51cdd68809c343f7405ac2e8",
"wavefile.js": "e17de4cd46f8a244d594c709fe3315f5",
"sequential.file.worker.js": "95883c410574a9f09693775cb449f923",
"OldWasmWorker.js": "970fce779749fe3bb875217be669e180",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"canvaskit.js": "c2b4e5f3d7a3d82aed024e7249a78487",
"myindex.js": "2a78b370e2312c1b82ca5b6406b7700f",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "854a5817279beba42f2f932fd60d34dc",
"sequential-shared-buffer-worker-processor.js": "18e9846bef17f589bfdbac87b58597a3",
"sequential-shared-buffer-worker.js": "4ffa02a156464e8f5eca23521043c4bc",
"assets/a.out.wasm": "4b60351c60132032e44a0dbdbf7c342e",
"assets/AssetManifest.json": "ede7d690719204f3f283473db2bdff90",
"assets/NOTICES": "755a8ecb907aaea4de01b32d4d423fa3",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "6d342eb68f170c97609e9da345464e5e",
"assets/fonts/MaterialIcons-Regular.otf": "7e7a6cccddf6d7b20012a548461d5d81",
"assets/assets/libopus.js": "e054d268a49a490e2cbd633d32c2f9ec",
"assets/assets/libopus.wasm": "3fa83e8321ab08a73c3a33e2c30f89ab",
"assets/a.out.js": "553a8c970bfea33716f6fd5a014b54fc",
"oldindex.html": "4013d20bbb32b28f9da30d0fe746f956",
"_ori_file.worker.js": "6abc174734fa77955bacb0332c6efef8",
"a.out.js": "ec99537be7d21d4c93e5a530d525fbea",
"index%20copy.html": "4cf7fbb5f85e6a8168e60cc13c2b2572",
"sequential-shared-buffer-worker-node.js": "742ece62d9df965aa77fb53aed6815e3",
"canvaskit/canvaskit.js": "c2b4e5f3d7a3d82aed024e7249a78487",
"canvaskit/profiling/canvaskit.js": "ae2949af4efc61d28a4a80fffa1db900",
"canvaskit/profiling/canvaskit.wasm": "95e736ab31147d1b2c7b25f11d4c32cd",
"canvaskit/canvaskit.wasm": "4b83d89d9fecbea8ca46f2f760c5a9ba"
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "/",
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
