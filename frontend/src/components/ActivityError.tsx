import { NetworkError, TimeoutError, ValidationError } from '../lib/api';

interface ErrorProps {
  error: Error;
  onRetry?: () => void;
}

export function ActivityError({ error, onRetry }: ErrorProps) {
  let message = 'Something went wrong';
  let description = 'Let\'s try that again!';

  if (error instanceof NetworkError) {
    message = 'Cannot connect to server';
    description = 'Please check your internet connection and try again.';
  } else if (error instanceof TimeoutError) {
    message = 'Taking too long to load';
    description = 'The server is being a bit slow. Want to try again?';
  } else if (error instanceof ValidationError) {
    message = 'Something looks wrong';
    description = 'The activity data doesn\'t look quite right. Let\'s try again!';
  }

  return (
    <div className="min-h-[300px] flex items-center justify-center p-4">
      <div className="text-center">
        <span role="img" aria-label="Error" className="text-5xl mb-4 block">
          😕
        </span>
        <h3 className="text-xl font-semibold text-gray-800 mb-2">{message}</h3>
        <p className="text-gray-600 mb-4">{description}</p>
        {onRetry && (
          <button
            onClick={onRetry}
            className="bg-sky-500 text-white px-6 py-2 rounded-full hover:bg-sky-600 transition-colors"
          >
            Try Again
          </button>
        )}
      </div>
    </div>
  );
}
