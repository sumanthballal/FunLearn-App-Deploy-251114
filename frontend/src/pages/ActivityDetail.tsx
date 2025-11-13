import React, { useEffect, useState } from "react";
import WebcamEmotion from "../components/WebcamEmotion";
import AudioNarrator from "../components/AudioNarrator";
import MiniGameMath from "../components/MiniGameMath";
import MiniGameScience from "../components/MiniGameScience";
import { useParams } from "react-router-dom";
import { motion } from "framer-motion";
import ReactMarkdown from "react-markdown";
import Confetti from "react-confetti";
import toast from "react-hot-toast";

interface Question {
  question: string;
  options: string[];
  correct: string;
  feedback: string;
}

interface ActivityContent {
  intro: string;
  steps: Array<{
    title: string;
    content: string;
  }>;
  quiz?: {
    questions: Question[];
  };
}

interface Activity {
  id: string;
  title: string;
  description: string;
  module: string;
  content: ActivityContent;
  media?: {
    type: string;
    src: string;
  };
}

export default function ActivityDetail() {
  const { id } = useParams();
  const [activity, setActivity] = useState<Activity | null>(null);
  const [showConfetti, setShowConfetti] = useState(false);
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [quizCompleted, setQuizCompleted] = useState(false);
  const [correctCount, setCorrectCount] = useState(0);
  const [selected, setSelected] = useState<string | null>(null);
  const [lock, setLock] = useState(false);
  const [emotion, setEmotion] = useState<string>("neutral");

  useEffect(() => {
    let mounted = true;
    (async () => {
      if (!id) return;
      try {
        const res = await fetch(`/api/activity/${encodeURIComponent(id)}`);
        if (!res.ok) throw new Error("Activity not found");
        const data = await res.json();
        if (mounted) setActivity(data);
      } catch (err) {
        if (mounted) {
          setActivity(null);
          toast.error("Couldn't load activity");
        }
      }
    })();
    return () => { mounted = false; };
  }, [id]);

  const handleAnswer = (answer: string) => {
    if (!activity?.content.quiz) return;
    
    const currentQuestion = activity.content.quiz.questions[currentQuestionIndex];
    const isCorrect = answer === currentQuestion.correct;
    
    if (isCorrect) {
      toast.success("Great! " + currentQuestion.feedback);
      setCorrectCount(c => c + 1);
      setSelected(answer);
      setLock(true);
      if (currentQuestionIndex + 1 < activity.content.quiz.questions.length) {
        setTimeout(()=>{
          setSelected(null); setLock(false);
          setCurrentQuestionIndex(prev => prev + 1);
        }, 600);
      } else {
        setQuizCompleted(true);
        setShowConfetti(true);
        setTimeout(() => setShowConfetti(false), 5000);
      }
    } else {
      toast.error("Try again!");
      setSelected(answer);
      setLock(true);
      setTimeout(()=>{ setSelected(null); setLock(false); }, 600);
    }
  };

  const markDone = async () => {
    try {
      const total = activity?.content?.quiz?.questions?.length ?? undefined;
      const score = typeof total === 'number' ? correctCount : undefined;
      const rec: any = { user: "local-user", module: activity?.module ?? "unknown", activity: id, timestamp: new Date().toISOString() };
      if (typeof score === 'number' && typeof total === 'number') { rec.score = score; rec.total = total; }
      await fetch("/api/progress", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(rec)
      });
      toast.success("Amazing job! Activity completed!");
      setShowConfetti(true);
      setTimeout(() => setShowConfetti(false), 5000);
    } catch {
      toast.error("Oops! Couldn't save progress");
    }
  };

  if (!activity) return (
    <div className="flex items-center justify-center min-h-screen bg-sky-50">
      <motion.div
        animate={{ scale: [1, 1.2, 1] }}
        transition={{ repeat: Infinity, duration: 2 }}
        className="text-2xl font-bold text-sky-600"
      >
        Loading...
      </motion.div>
    </div>
  );

  return (
    <div className="min-h-screen p-8 bg-sky-50">
      <div className="max-w-5xl mx-auto mb-6 grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <WebcamEmotion
            user="local-user"
            activity={id as string}
            onEmotion={(e)=> setEmotion(e.emotion)}
            intervalMs={10000}
          />
          {emotion === 'sad' && (
            <div className="mt-2 text-rose-600 font-semibold">Don't worry, try again! You can do it!</div>
          )}
        </div>
        <div className="lg:col-span-1">
          <div className="p-4 bg-white rounded-xl shadow mb-4">
            <div className="font-semibold mb-2">Narration</div>
            <AudioNarrator text={`Let's learn ${activity?.title || 'together'}!`} />
          </div>
          <div className="p-4 bg-white rounded-xl shadow">
            <div className="font-semibold mb-3">Mini Game</div>
            { (activity?.module || '').toLowerCase().includes('math') && <MiniGameMath /> }
            { (activity?.module || '').toLowerCase().includes('science') && <MiniGameScience /> }
            { !(activity?.module || '').toLowerCase().includes('math') && !(activity?.module || '').toLowerCase().includes('science') && (
              <div className="text-sm text-gray-600">No game for this subject yet. Enjoy the lesson!</div>
            )}
          </div>
        </div>
      </div>
      {showConfetti && <Confetti />}
      <div className="max-w-4xl mx-auto bg-white rounded-2xl shadow-xl p-8">
        <motion.h1 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-4xl font-bold mb-6 text-sky-600"
        >
          {activity.title}
        </motion.h1>

        <div className="prose max-w-none mb-8 emoji">
          <ReactMarkdown>{activity.content.intro}</ReactMarkdown>
        </div>

        {activity.content.steps.map((step, index) => (
          <motion.div
            key={index}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: index * 0.2 }}
            className="mb-8 p-6 bg-sky-50 rounded-xl"
          >
            <h3 className="text-2xl font-bold mb-4 text-sky-700">{step.title}</h3>
            <div className="prose emoji"> <ReactMarkdown>{step.content}</ReactMarkdown> </div>
          </motion.div>
        ))}

        {activity.content.quiz && !quizCompleted && (
          <div className="mt-8 p-6 bg-indigo-50 rounded-xl">
            <h3 className="text-2xl font-bold mb-6 text-indigo-700">Quiz Time!</h3>
        <div className="space-y-4 emoji">
          <p className="text-xl mb-4">{activity.content.quiz.questions[currentQuestionIndex].question}</p>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {activity.content.quiz.questions[currentQuestionIndex].options.map((option, idx) => {
                  const isRight = option === activity.content.quiz!.questions[currentQuestionIndex].correct;
                  const isSelected = selected === option;
                  const cls = isSelected ? (isRight ? 'bg-green-100 border-green-400' : 'bg-red-100 border-red-400') : 'bg-white hover:bg-indigo-100';
                  return (
                  <motion.button
                    key={idx}
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    disabled={lock}
                    onClick={() => handleAnswer(option)}
                    className={`p-4 text-lg rounded-xl shadow-md transition-colors border ${cls}`}
                  >
                    {option}
                  </motion.button>
                );})}
              </div>
            </div>
          </div>
        )}

        {(quizCompleted || !activity.content.quiz) && (
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={markDone}
            className="mt-8 px-8 py-4 bg-gradient-to-r from-sky-500 to-indigo-500 text-white text-xl font-bold rounded-xl shadow-lg hover:shadow-xl transition-all"
          >
            Mark as Done!
          </motion.button>
        )}
      </div>
    </div>
  );
}


