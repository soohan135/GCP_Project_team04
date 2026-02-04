import React from 'react';
import { Settings } from 'lucide-react';
import { Mascot } from './Mascot';

export const Header: React.FC = () => {
  return (
    <div className="bg-brand-50 px-5 pt-12 pb-4">
      <div className="flex justify-between items-center mb-0">
        <div className="flex items-center gap-2.5">
          <div className="bg-white w-10 h-10 rounded-xl flex items-center justify-center border border-brand-100 shadow-sm">
             <Mascot type="idle" className="w-8 h-8" />
          </div>
          <div>
            <div className="flex items-center h-6">
                <h1 className="text-xl font-extrabold text-slate-800 leading-none tracking-tight relative z-10">카</h1>
                {/* Frequency Wave Graphic attached to 'ㅏ' */}
                <div className="relative w-10 h-6 flex items-center justify-center -ml-0.5 -mr-1">
                   <svg viewBox="0 0 40 20" className="w-full h-full text-brand-500 overflow-visible" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M0 10.5 H 4 L 9 3 L 15 17 L 21 3 L 26 10.5 H 40" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
                      <circle cx="9" cy="3" r="1.5" fill="#38bdf8" className="animate-pulse"/>
                      <circle cx="15" cy="17" r="1.5" fill="#38bdf8" className="animate-pulse delay-75"/>
                      <circle cx="21" cy="3" r="1.5" fill="#38bdf8" className="animate-pulse delay-150"/>
                   </svg>
                </div>
                <h1 className="text-xl font-extrabold text-slate-800 leading-none tracking-tight">더라</h1>
            </div>
            <span className="text-[11px] text-brand-500 font-bold bg-white px-1.5 py-0.5 rounded-md mt-1.5 inline-block shadow-sm">AI 수리 견적</span>
          </div>
        </div>
        <button className="w-10 h-10 flex items-center justify-center text-slate-400 hover:text-slate-600 hover:bg-white rounded-xl transition-all">
          <Settings size={22} />
        </button>
      </div>
    </div>
  );
};