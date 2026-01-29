import React from 'react';
import { Settings, Zap } from 'lucide-react';

export const Header: React.FC = () => {
  return (
    <div className="flex justify-between items-center px-6 py-5 bg-transparent z-10 relative">
      <div className="flex items-center space-x-3">
        <div className="bg-brand-500 p-2 rounded-xl border-2 border-slate-800 shadow-[2px_2px_0px_0px_rgba(30,41,59,1)]">
          <Zap className="text-yellow-300 fill-yellow-300" size={24} />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-slate-800 tracking-tight brand-font italic">CarFix</h1>
          <div className="flex items-center space-x-1">
             <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
             <p className="text-xs text-brand-600 font-bold">AI 정비소 오픈</p>
          </div>
        </div>
      </div>
      <button className="p-2 rounded-xl bg-white border-2 border-brand-100 hover:border-brand-300 text-slate-600 transition-colors">
        <Settings size={22} />
      </button>
    </div>
  );
};