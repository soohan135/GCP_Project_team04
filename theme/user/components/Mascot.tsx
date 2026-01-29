import React from 'react';

interface MascotProps {
  message?: string;
  expression?: 'happy' | 'thinking' | 'waiting';
}

export const Mascot: React.FC<MascotProps> = ({ message, expression = 'happy' }) => {
  // Simple CSS based cute robot representation
  return (
    <div className="flex flex-col items-center justify-center my-4 animate-float">
      {message && (
        <div className="bg-white px-6 py-3 rounded-t-3xl rounded-br-3xl rounded-bl-sm shadow-md mb-4 relative max-w-[80%] border-2 border-sky-100">
          <p className="text-slate-700 font-medium text-center cute-font text-lg leading-snug">
            {message}
          </p>
          <div className="absolute -bottom-[8px] left-[20px] w-4 h-4 bg-white border-b-2 border-r-2 border-sky-100 transform rotate-45"></div>
        </div>
      )}
      
      {/* Robot Body */}
      <div className="relative group cursor-pointer">
        <div className="w-24 h-20 bg-sky-400 rounded-3xl shadow-xl shadow-sky-200 relative flex items-center justify-center overflow-hidden border-4 border-white">
          {/* Eyes */}
          <div className="flex space-x-3 z-10">
             {expression === 'thinking' ? (
               <>
                 <div className="w-3 h-3 bg-slate-800 rounded-full animate-pulse"></div>
                 <div className="w-3 h-3 bg-slate-800 rounded-full animate-pulse delay-75"></div>
               </>
             ) : (
                <>
                 <div className="w-3 h-4 bg-slate-800 rounded-full">
                    <div className="w-1 h-1 bg-white rounded-full ml-1 mt-1"></div>
                 </div>
                 <div className="w-3 h-4 bg-slate-800 rounded-full">
                    <div className="w-1 h-1 bg-white rounded-full ml-1 mt-1"></div>
                 </div>
               </>
             )}
          </div>
          {/* Blush */}
          <div className="absolute top-10 left-3 w-3 h-2 bg-pink-300 rounded-full opacity-60"></div>
          <div className="absolute top-10 right-3 w-3 h-2 bg-pink-300 rounded-full opacity-60"></div>
          
          {/* Mouth */}
          <div className="absolute bottom-5 w-4 h-2 border-b-2 border-slate-800 rounded-full"></div>
        </div>
        {/* Antenna */}
        <div className="absolute -top-4 left-1/2 transform -translate-x-1/2 w-1 h-4 bg-slate-300 z-0"></div>
        <div className="absolute -top-6 left-1/2 transform -translate-x-1/2 w-3 h-3 bg-red-400 rounded-full shadow-lg animate-pulse z-0"></div>
        
        {/* Arms */}
        <div className="absolute top-8 -left-3 w-4 h-8 bg-sky-500 rounded-full -rotate-12 border-2 border-white"></div>
        <div className="absolute top-8 -right-3 w-4 h-8 bg-sky-500 rounded-full rotate-12 border-2 border-white"></div>
      </div>
    </div>
  );
};
