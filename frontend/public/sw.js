const CACHE_NAME = 'funlearn-v1';
const OFFLINE_URL = '/offline.html';

const ASSETS_TO_CACHE = [
  '/',
  '/index.html',
  '/assets/math-balloon.svg',
  '/assets/science-cycle.svg',
  '/assets/reading-fox.svg',
  '/assets/art-doodle.svg',
  '/assets/quiz/quiz1.svg',
  '/assets/quiz/quiz2.svg',
  '/assets/quiz/quiz3.svg',
  '/assets/quiz/quiz4.svg',
  '/assets/quiz/quiz5.svg',
  '/assets/quiz/quiz6.svg',
  '/assets/default-activity.svg',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(ASSETS_TO_CACHE))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keyList) => {
      return Promise.all(keyList.map((key) => {
        if (key !== CACHE_NAME) {
          return caches.delete(key);
        }
      }));
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  // Skip cross-origin requests
  if (!event.request.url.startsWith(self.location.origin)) return;
  
  // Handle API requests differently (network-first with timeout)
  if (event.request.url.includes('/api/')) {
    event.respondWith(
      Promise.race([
        fetch(event.request.clone())
          .then((response) => {
            if (!response.ok) throw new Error('Network response was not ok');
            return response;
          }),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Network timeout')), 5000)
        )
      ]).catch(() => {
        return caches.match(event.request);
      })
    );
    return;
  }

  // For all other requests (assets, pages) use cache-first
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        if (response) {
          return response; // Cache hit
        }
        return fetch(event.request.clone())
          .then((response) => {
            if (!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }
            // Cache new successful responses
            const responseToCache = response.clone();
            caches.open(CACHE_NAME)
              .then((cache) => {
                cache.put(event.request, responseToCache);
              });
            return response;
          })
          .catch(() => {
            // If offline and no cache, show offline page for navigation requests
            if (event.request.mode === 'navigate') {
              return caches.match(OFFLINE_URL);
            }
            // For images, return a placeholder
            if (event.request.destination === 'image') {
              return new Response(
                `<svg xmlns='http://www.w3.org/2000/svg' width='400' height='300' viewBox='0 0 400 300'>
                  <rect fill='#eaf6ff' width='100%' height='100%'/>
                  <text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' fill='#92c6e6' font-family='Arial'>
                    Image unavailable offline
                  </text>
                </svg>`,
                {
                  headers: { 'Content-Type': 'image/svg+xml' }
                }
              );
            }
          });
      })
  );
});