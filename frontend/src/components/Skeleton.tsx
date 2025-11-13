interface SkeletonProps {
  className?: string;
  aspectRatio?: number;
}

export function Skeleton({ className = '', aspectRatio }: SkeletonProps) {
  const style = aspectRatio ? { paddingBottom: `${(1 / aspectRatio) * 100}%` } : undefined;
  
  return (
    <div className={`relative ${className}`} style={style}>
      <div className="absolute inset-0 bg-gray-200 animate-pulse rounded" />
    </div>
  );
}

export function ActivityCardSkeleton() {
  return (
    <div className="bg-white/80 p-6 rounded-2xl shadow-md">
      <Skeleton className="mb-4" aspectRatio={16/9} />
      <div className="space-y-2">
        <Skeleton className="h-6 w-3/4" />
        <Skeleton className="h-4 w-1/2" />
      </div>
    </div>
  );
}

export function QuizOptionSkeleton() {
  return (
    <div className="border rounded overflow-hidden">
      <Skeleton aspectRatio={4/3} />
    </div>
  );
}

export function ModuleCardSkeleton() {
  return (
    <div className="bg-white/80 p-6 rounded-2xl shadow-md">
      <div className="h-6 bg-gray-200 animate-pulse rounded" />
    </div>
  );
}
