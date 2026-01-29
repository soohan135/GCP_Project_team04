import React from 'react';
import { Home, FileText, MessageCircle, MapPin } from 'lucide-react';
import { AppView } from '../types';

interface NavBarProps {
  currentView: AppView;
  setView: (view: AppView) => void;
}

export const NavBar: React.FC<NavBarProps> = ({ currentView, setView }) => {
  const navItems = [
    { id: AppView.HOME, icon: Home, label: '홈' },
    { id: AppView.ESTIMATE, icon: FileText, label: '견적' },
    { id: AppView.CHAT, icon: MessageCircle, label: '상담' },
    { id: AppView.MAP, icon: MapPin, label: '정비소' },
  ];

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white border-t-4 border-brand-100 p-2 pb-4 z-50 rounded-t-3xl shadow-negative">
      <div className="flex justify-around items-end h-16">
        {navItems.map((item) => {
          const isActive = currentView === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setView(item.id)}
              className={`group flex flex-col items-center justify-end pb-2 w-16 transition-all duration-200 ${
                isActive ? '-translate-y-4' : 'hover:-translate-y-1'
              }`}
            >
              <div 
                className={`
                  p-3 rounded-2xl border-2 transition-all duration-200
                  ${isActive 
                    ? 'bg-brand-500 border-slate-800 text-white shadow-[4px_4px_0px_0px_rgba(30,41,59,1)]' 
                    : 'bg-white border-transparent text-slate-400 group-hover:bg-brand-50'}
                `}
              >
                <item.icon size={24} strokeWidth={2.5} />
              </div>
              
              <span className={`text-xs font-bold mt-1 transition-opacity ${
                isActive ? 'text-brand-600 opacity-100' : 'text-slate-300 opacity-0 group-hover:opacity-100'
              }`}>
                {item.label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
};