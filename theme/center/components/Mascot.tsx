import React from 'react';

interface MascotProps {
  message?: string;
  expression?: 'happy' | 'thinking' | 'waiting';
}

export const Mascot: React.FC<MascotProps> = ({ message, expression = 'happy' }) => {
  return (
    <div className="flex flex-col items-center justify-center my-4 animate-float">
      {message && (
        <div className="bg-white px-6 py-4 rounded-2xl border-b-4 border-r-4 border-brand-200 shadow-sm mb-5 relative max-w-[85%] z-10">
          <p className="text-slate-700 font-medium text-center brand-font text-lg leading-snug">
            {message}
          </p>
          <div className="absolute -bottom-3 left-1/2 transform -translate-x-1/2 w-4 h-4 bg-white rotate-45 border-b-4 border-r-4 border-brand-200"></div>
        </div>
      )}
      
      {/* Robot Bolt Body */}
      <div className="relative group cursor-pointer drop-shadow-xl">
        {/* Head */}
        <div className="w-28 h-24 bg-brand-500 rounded-2xl relative flex items-center justify-center overflow-hidden border-[3px] border-slate-800">
           {/* Face Plate */}
           <div className="w-20 h-14 bg-brand-100 rounded-xl flex items-center justify-center space-x-2 border-2 border-slate-800/20">
              {/* Eyes */}
              {expression === 'thinking' ? (
               <>
                 <div className="w-4 h-4 border-4 border-slate-800 rounded-full animate-spin border-t-transparent"></div>
                 <div className="w-4 h-4 border-4 border-slate-800 rounded-full animate-spin border-t-transparent animation-delay-150"></div>
               </>
             ) : (
                <>
                 <div className="w-4 h-6 bg-slate-800 rounded-full relative overflow-hidden">
                    <div className="absolute top-1 right-1 w-1.5 h-1.5 bg-white rounded-full"></div>
                 </div>
                 <div className="w-4 h-6 bg-slate-800 rounded-full relative overflow-hidden">
                    <div className="absolute top-1 right-1 w-1.5 h-1.5 bg-white rounded-full"></div>
                 </div>
               </>
             )}
           </div>
           
           {/* Bolt Ears */}
           <div className="absolute -left-3 top-8 w-4 h-6 bg-yellow-400 border-2 border-slate-800 rounded-sm"></div>
           <div className="absolute -right-3 top-8 w-4 h-6 bg-yellow-400 border-2 border-slate-800 rounded-sm"></div>
        </div>

        {/* Top Antenna (Lightning Bolt) */}
        <div className="absolute -top-8 left-1/2 transform -translate-x-1/2 w-8 h-8 flex justify-center animate-wiggle origin-bottom">
           <svg viewBox="0 0 24 24" fill="currentColor" className="w-8 h-8 text-yellow-400 drop-shadow-sm stroke-slate-800 stroke-2">
             <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
           </svg>
        </div>
        
        {/* Neck */}
        <div className="absolute -bottom-2 left-1/2 transform -translate-x-1/2 w-12 h-4 bg-slate-700 rounded-b-lg -z-10"></div>
      </div>
    </div>
  );
};