import React from 'react';
import { Settings, Cloud } from 'lucide-react';

export const Header: React.FC = () => {
  return (
    <div className="flex justify-between items-center p-6 bg-transparent z-10 relative">
      <div className="flex items-center space-x-2">
        <div className="bg-sky-500 p-2 rounded-2xl shadow-lg shadow-sky-200">
          <Cloud className="text-white fill-white" size={24} />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-slate-800 tracking-tight">CarFix</h1>
          <p className="text-xs text-sky-500 font-bold -mt-1">AI 클라우드 견적</p>
        </div>
      </div>
      <button className="p-2 rounded-full bg-white/50 hover:bg-white text-slate-600 transition-colors">
        <Settings size={24} />
      </button>
    </div>
  );
};
