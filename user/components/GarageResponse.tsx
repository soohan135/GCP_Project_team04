import React from 'react';
import { Warehouse, ChevronDown, MapPin } from 'lucide-react';

export const GarageResponse: React.FC = () => {
  // Mock data based on the screenshot
  const responses = [
    {
      id: 1,
      name: '백제자동차정비',
      address: '인천광역시 부평구 주부토로151번길 27',
      date: '01/29 11:36',
      status: 'new'
    }
  ];

  return (
    <div className="min-h-screen bg-brand-50 pb-24 font-sans animate-in fade-in duration-300">
      <div className="px-5 pt-8 pb-6">
        {/* Title Section */}
        <div className="mb-8">
          <h2 className="text-2xl font-extrabold text-slate-800 tracking-tight mb-2">정비소 응답 현황</h2>
          <p className="text-slate-500 text-sm font-medium">
            정비소에서 보낸 견적 제안을 확인하세요.
          </p>
        </div>

        {/* List Section */}
        <div className="space-y-4">
          {responses.map((item) => (
            <div 
              key={item.id} 
              className="bg-white p-5 rounded-[24px] shadow-sm border border-slate-100 flex items-start gap-4 active:scale-[0.99] transition-transform cursor-pointer"
            >
              {/* Icon */}
              <div className="w-12 h-12 rounded-2xl bg-brand-50 flex items-center justify-center text-brand-500 shrink-0 border border-brand-100">
                <Warehouse size={24} strokeWidth={2} />
              </div>

              {/* Content */}
              <div className="flex-1 min-w-0 pt-0.5">
                <div className="flex justify-between items-start mb-1.5">
                  <h3 className="font-bold text-slate-800 text-[16px] truncate pr-2">{item.name}</h3>
                  <span className="text-slate-400 text-[11px] font-medium shrink-0 pt-0.5 tracking-tight">{item.date}</span>
                </div>
                
                <div className="flex justify-between items-end">
                   <div className="flex items-center text-slate-400 text-[13px] truncate pr-4">
                      <MapPin size={12} className="mr-1 shrink-0 opacity-70" />
                      <span className="truncate">{item.address}</span>
                   </div>
                   <ChevronDown className="text-slate-300 shrink-0 mb-0.5" size={20} />
                </div>
              </div>
            </div>
          ))}

           {/* Empty State / Placeholder for more items */}
           {responses.length < 3 && (
             <div className="py-8 text-center">
                <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
                    <span className="animate-pulse w-2 h-2 bg-slate-300 rounded-full mx-0.5"></span>
                    <span className="animate-pulse w-2 h-2 bg-slate-300 rounded-full mx-0.5 delay-75"></span>
                    <span className="animate-pulse w-2 h-2 bg-slate-300 rounded-full mx-0.5 delay-150"></span>
                </div>
                <p className="text-xs text-slate-400 font-medium">주변 정비소에 견적을 요청하고 있어요...</p>
             </div>
           )}
        </div>
      </div>
    </div>
  );
};