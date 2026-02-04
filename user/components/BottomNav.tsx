import React from 'react';
import { Home, FileText, MessageCircle, MapPin, Store } from 'lucide-react';
import { Tab } from '../types';

interface BottomNavProps {
  activeTab: Tab;
  onTabChange: (tab: Tab) => void;
}

export const BottomNav: React.FC<BottomNavProps> = ({ activeTab, onTabChange }) => {
  const navItems = [
    { id: 'home' as Tab, icon: Home, label: '홈' },
    { id: 'preview' as Tab, icon: FileText, label: '견적 미리보기' },
    { id: 'response' as Tab, icon: Store, label: '정비소 응답' },
    { id: 'chat' as Tab, icon: MessageCircle, label: '채팅' },
    { id: 'map' as Tab, icon: MapPin, label: '근처 정비소' },
  ];

  return (
    <div className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[430px] bg-white border-t border-slate-100 px-6 py-2 pb-8 z-50 rounded-t-[32px] shadow-[0_-8px_30px_rgba(0,0,0,0.03)]">
      <div className="flex justify-between items-center max-w-lg mx-auto">
        {navItems.map((item) => {
          const isActive = activeTab === item.id;
          return (
            <button 
              key={item.id}
              onClick={() => onTabChange(item.id)}
              className={`
                flex-1 flex flex-col items-center justify-center gap-1 py-1 transition-all duration-300
                ${isActive ? 'text-brand-600' : 'text-slate-400 hover:text-slate-500'}
              `}
            >
              <div className={`
                p-2.5 rounded-2xl transition-all duration-300
                ${isActive ? 'bg-brand-50 shadow-sm shadow-brand-100 -translate-y-1' : 'bg-transparent'}
              `}>
                 <item.icon size={24} strokeWidth={isActive ? 2.8 : 2.2} />
              </div>
              <span className={`
                text-[10px] font-extrabold tracking-tight transition-all duration-300
                ${isActive ? 'text-brand-600 opacity-100' : 'text-slate-300 opacity-80'}
              `}>
                {item.label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
};