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
    { id: AppView.CHAT, icon: MessageCircle, label: '채팅' },
    { id: AppView.MAP, icon: MapPin, label: '정비소' },
  ];

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white/90 backdrop-blur-md rounded-t-3xl shadow-[0_-5px_20px_rgba(0,0,0,0.05)] border-t border-sky-100 p-4 z-50">
      <div className="flex justify-around items-center">
        {navItems.map((item) => {
          const isActive = currentView === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setView(item.id)}
              className={`flex flex-col items-center space-y-1 transition-all duration-300 ${
                isActive ? 'text-sky-500 transform -translate-y-2' : 'text-slate-400'
              }`}
            >
              <div className={`p-3 rounded-full ${isActive ? 'bg-sky-100 shadow-md' : 'bg-transparent'}`}>
                <item.icon size={24} strokeWidth={isActive ? 2.5 : 2} />
              </div>
              <span className={`text-xs font-bold ${isActive ? 'opacity-100' : 'opacity-70'}`}>
                {item.label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
};
