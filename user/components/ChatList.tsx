import React from 'react';
import { Search } from 'lucide-react';

export const ChatList: React.FC = () => {
  const chatItems = [
    {
      id: 1,
      garageName: '백제자동차정비',
      damageType: '앞 펜더 (왼쪽) - 스크래치',
      partsDescription: '손상 부위 정밀 점검 필요, 주변 부위 도장',
      lastMessage: '안녕하세요',
      image: 'https://images.unsplash.com/photo-1619682817481-e994891cd1f5?auto=format&fit=crop&q=80&w=150&h=150',
    }
  ];

  return (
    <div className="min-h-screen bg-brand-50 pb-24 font-sans animate-in fade-in duration-300">
      <div className="px-5 pt-4 pb-6">
        {/* Search Bar */}
        <div className="bg-white rounded-full shadow-sm border border-brand-100 flex items-center px-4 py-3.5 mb-6">
           <Search size={20} className="text-slate-400 mr-3" />
           <input 
             type="text" 
             placeholder="정비소, 서비스 검색..." 
             className="flex-1 bg-transparent text-slate-700 placeholder-slate-400 outline-none text-sm font-medium"
           />
        </div>

        {/* Chat List */}
        <div className="space-y-4">
          {chatItems.map((item) => (
            <div 
              key={item.id} 
              className="bg-white p-4 rounded-[24px] shadow-sm border border-slate-100 flex gap-4 active:scale-[0.99] transition-transform cursor-pointer"
            >
              {/* Image */}
              <div className="w-[88px] h-[88px] shrink-0 rounded-2xl bg-slate-100 overflow-hidden border border-slate-50">
                 <img src={item.image} alt={item.garageName} className="w-full h-full object-cover" />
              </div>

              {/* Content */}
              <div className="flex-1 min-w-0 py-0.5 flex flex-col h-[88px]">
                <div className="flex-1 min-w-0">
                   <div className="flex justify-between items-start mb-0.5">
                      <h3 className="font-bold text-slate-800 text-[16px] leading-tight truncate pr-2">{item.garageName}</h3>
                   </div>
                   
                   <div className="space-y-0.5 mb-2">
                     <p className="text-[11px] text-slate-400 truncate leading-relaxed">
                       <span className="text-slate-500 font-medium">손상 유형:</span> {item.damageType}
                     </p>
                     <p className="text-[11px] text-slate-400 truncate leading-relaxed">
                       <span className="text-slate-500 font-medium">부품:</span> {item.partsDescription} ...
                     </p>
                   </div>
                </div>
                
                <p className="text-[14px] text-slate-800 font-medium truncate">{item.lastMessage}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};