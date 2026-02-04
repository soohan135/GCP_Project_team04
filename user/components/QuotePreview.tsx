import React from 'react';
import { Search, ChevronRight } from 'lucide-react';

export const QuotePreview: React.FC = () => {
  // Mock data to match the screenshot
  const quotes = [
    {
      id: 1,
      date: '2026-02-02T10:01:19.433159',
      part: '범퍼',
      costRange: '₩202,500 ~ ₩270,000',
      image: 'https://images.unsplash.com/photo-1489824904134-891ab64532f1?auto=format&fit=crop&q=80&w=150&h=150',
      status: '저장됨'
    },
    {
      id: 2,
      date: '2026-01-28T19:26:13.143220',
      part: '스크래치',
      costRange: '₩67,500 ~ ₩90,000',
      image: 'https://images.unsplash.com/photo-1619682817481-e994891cd1f5?auto=format&fit=crop&q=80&w=150&h=150',
      status: '저장됨'
    }
  ];

  return (
    <div className="min-h-screen bg-brand-50 pb-24 font-sans animate-in fade-in duration-300">
      <div className="px-5 pt-4 pb-6">
        {/* Search Bar */}
        <div className="bg-white rounded-full shadow-sm border border-brand-100 flex items-center px-4 py-3.5 mb-8">
           <Search size={20} className="text-slate-400 mr-3" />
           <input 
             type="text" 
             placeholder="정비소, 서비스 검색..." 
             className="flex-1 bg-transparent text-slate-700 placeholder-slate-400 outline-none text-sm font-medium"
           />
        </div>

        {/* Title Section */}
        <div className="mb-6">
          <h2 className="text-2xl font-extrabold text-slate-800 tracking-tight mb-2">견적 미리보기</h2>
          <p className="text-brand-500 text-sm font-bold">
            총 <span>{quotes.length}개의 저장된 견적</span>이 있습니다.
          </p>
        </div>

        {/* List */}
        <div className="space-y-4">
          {quotes.map((quote) => (
            <div key={quote.id} className="bg-white rounded-[28px] p-5 shadow-sm border border-slate-100 relative active:scale-[0.98] transition-transform duration-200 cursor-pointer group">
               <div className="flex justify-between items-start mb-3">
                 <span className="text-slate-400 text-[11px] font-semibold tracking-wide">{quote.date}</span>
                 <span className="bg-amber-50 text-amber-500 text-[10px] font-bold px-2 py-1 rounded-lg border border-amber-100">
                   {quote.status}
                 </span>
               </div>
               
               <div className="flex items-center gap-4">
                  <div className="w-[72px] h-[72px] shrink-0 rounded-2xl bg-slate-100 overflow-hidden border border-slate-50 relative">
                    <img src={quote.image} alt={quote.part} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />
                  </div>
                  
                  <div className="flex-1 min-w-0">
                     <h3 className="font-bold text-slate-800 text-lg mb-1 truncate">{quote.part}</h3>
                     <p className="text-brand-500 font-extrabold text-[17px] tracking-tight">{quote.costRange}</p>
                  </div>
                  
                  <ChevronRight className="text-slate-300 group-hover:text-brand-400 transition-colors" size={24} />
               </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};