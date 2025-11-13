import React from "react";
import { Link } from "react-router-dom";

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-blue-50 via-sky-50 to-indigo-50 p-6">
      <div className="max-w-6xl w-full px-4">
        <div className="flex flex-col items-center justify-center space-y-6 mb-12">
          <h1 className="font-brand text-5xl md:text-6xl text-blue-700">FunLearn</h1>
          <p className="font-body text-lg md:text-xl text-gray-600 max-w-2xl text-center">
            Emotion-aware learning for kids - safe, fun, and adaptive
          </p>
        </div>

        <div className="grid gap-6 mb-12 max-w-4xl mx-auto">
          <div className="bg-white/70 backdrop-blur p-6 md:p-8 rounded-xl shadow-md border border-blue-100">
            <h2 className="font-display text-2xl text-blue-800 font-semibold mb-2">Smart Learning Experience</h2>
            <p className="text-gray-600">Our platform adapts to your child's learning pace and emotional state to keep lessons engaging and effective.</p>
          </div>

          <div className="bg-white/70 backdrop-blur p-6 md:p-8 rounded-xl shadow-md border border-blue-100">
            <h2 className="font-display text-2xl text-blue-800 font-semibold mb-2">Interactive Learning Modules</h2>
            <p className="text-gray-600">Explore Math, Science, Reading, and Art with hands-on activities and adaptive quizzes.</p>
          </div>
        </div>

        <div className="text-center">
          <Link
            to="/login"
            className="inline-flex items-center justify-center font-display text-lg bg-blue-600 text-white px-6 py-3 rounded-lg shadow hover:bg-blue-700 transition-all duration-200"
          >
            Start Learning
            <svg className="w-4 h-4 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
            </svg>
          </Link>
        </div>
      </div>
    </div>
  );
}
