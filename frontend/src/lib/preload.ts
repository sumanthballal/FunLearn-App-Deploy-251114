// Keep track of what's already been preloaded
const preloadedAssets = new Set<string>();

// Preload an image
export function preloadImage(src: string): Promise<void> {
  if (!src || preloadedAssets.has(src)) return Promise.resolve();
  
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      preloadedAssets.add(src);
      resolve();
    };
    img.onerror = reject;
    img.src = src;
  });
}

// Preload multiple images in parallel
export function preloadImages(srcs: string[]): Promise<void[]> {
  const uniqueSrcs = srcs.filter(src => !preloadedAssets.has(src));
  return Promise.all(uniqueSrcs.map(preloadImage));
}

// Mark assets as important with resource hints
export function addResourceHints(urls: string[]) {
  urls.forEach(url => {
    // Skip if already hinted
    if (document.querySelector(`link[href="${url}"]`)) return;

    const link = document.createElement('link');
    link.rel = url.endsWith('.css') ? 'preload' : 'prefetch';
    link.as = url.endsWith('.css') ? 'style' : 'image';
    link.href = url;
    document.head.appendChild(link);
  });
}

// Helper to extract image URLs from an activity
export function getActivityAssetUrls(activity: any): string[] {
  const urls: string[] = [];
  
  // Add media URLs
  if (activity.media?.src) {
    urls.push(activity.media.src);
  }

  // Add quiz image URLs
  if (activity.type === 'quiz') {
    const questions = sampleImageQs[activity.module?.toLowerCase()] || [];
    questions.forEach(q => {
      q.opts.forEach((opt: any) => {
        if (opt.img) urls.push(opt.img);
      });
    });
  }

  return urls;
}