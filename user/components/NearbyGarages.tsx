import React from 'react';
import { Map, RotateCcw, Star, Navigation, ChevronDown } from 'lucide-react';

export const NearbyGarages: React.FC = () => {
  const garages = [
    {
      id: 1,
      name: '백제자동차정비',
      address: '인천광역시 부평구 주부토로151번길 47 (갈산동)',
      phone: '032-527-4842',
      rating: 4.5,
      reviews: 2,
      distance: '0.2km'
    },
    {
      id: 2,
      name: '성도카센타',
      address: '인천광역시 부평구 길주남로 8 (부평동)',
      phone: '032-502-5767',
      rating: 0.0,
      reviews: 0,
      distance: '0.4km'
    },
    {
      id: 3,
      name: '현대자동차공업사',
      address: '인천광역시 부평구 부평대로 224 (갈산동)',
      phone: '032-511-4334',
      rating: 0.0,
      reviews: 0,
      distance: '0.4km'
    },
    {
      id: 4,
      name: '엄지자동차공업사',
      address: '인천광역시 부평구 길주남로 6 (부평동)',
      phone: '032-551-7723',
      rating: 0.0,
      reviews: 0,
      distance: '0.4km'
    },
    {
      id: 5,
      name: '화이트보쉬카서비스',
      address: '인천광역시 부평구 길주남로 23-1 (부평동)',
      phone: '032-545-8572',
      rating: 0.0,
      reviews: 0,
      distance: '0.5km'
    }
  ];

  return (
    <div className="min-h-screen bg-brand-50 pb-24 font-sans animate-in fade-in duration-300">
      <div className="px-5 pt-8 pb-6">
        {/* Header */}
        <div className="flex justify-between items-start mb-6">
          <div>
            <h2 className="text-2xl font-extrabold text-slate-800 tracking-tight mb-2">내 근처 정비소 (10km)</h2>
            <p className="text-brand-500 text-sm font-bold">
              총 40개의 정비소가 검색되었습니다.
            </p>
          </div>
          <button className="p-2 text-slate-400 hover:text-brand-500 transition-colors bg-white rounded-full shadow-sm border border-slate-100 active:scale-95 transform duration-200">
            <RotateCcw size={20} />
          </button>
        </div>

        {/* List */}
        <div className="space-y-4">
          {garages.map((garage) => (
            <div 
              key={garage.id} 
              className="bg-white p-5 rounded-[24px] shadow-sm border border-slate-100 flex items-start gap-4 active:scale-[0.99] transition-transform cursor-pointer group"
            >
              {/* Icon */}
              <div className="w-12 h-12 rounded-2xl bg-brand-50 flex items-center justify-center text-brand-500 shrink-0 border border-brand-100 mt-1">
                <Map size={24} strokeWidth={2} />
              </div>

              {/* Content */}
              <div className="flex-1 min-w-0">
                <div className="flex justify-between items-start">
                   <h3 className="font-bold text-slate-800 text-[16px] mb-1 truncate">{garage.name}</h3>
                   <ChevronDown className="text-slate-300 shrink-0 group-hover:text-brand-400 transition-colors" size={20} />
                </div>
                
                <p className="text-[13px] text-slate-500 truncate mb-1">{garage.address}</p>
                <p className="text-[13px] text-slate-400 mb-2">{garage.phone}</p>
                
                <div className="flex items-center gap-3 text-[12px] font-bold">
                   <div className="flex items-center text-slate-800">
                      <Star size={14} className="text-amber-400 fill-amber-400 mr-1" />
                      <span>{garage.rating.toFixed(1)}</span>
                      <span className="text-slate-400 ml-1 font-medium">리뷰 {garage.reviews}</span>
                   </div>
                   <div className="flex items-center text-brand-500">
                      <Navigation size={12} className="mr-1 fill-brand-500" />
                      <span>{garage.distance}</span>
                   </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};