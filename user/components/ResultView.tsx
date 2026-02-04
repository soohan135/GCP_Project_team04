import React from 'react';
import { DamageEstimate, RepairPart } from '../types';
import { ArrowLeft, RefreshCw, AlertTriangle, Wrench } from 'lucide-react';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from 'recharts';
import { Mascot } from './Mascot';

interface ResultViewProps {
  data: DamageEstimate;
  onReset: () => void;
}

export const ResultView: React.FC<ResultViewProps> = ({ data, onReset }) => {
  const chartData = data.parts.map(part => ({
    name: part.name,
    value: part.cost
  }));

  const COLORS = ['#38bdf8', '#818cf8', '#34d399', '#f472b6', '#fbbf24'];

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('ko-KR', { style: 'currency', currency: 'KRW' }).format(val);
  };

  return (
    <div className="min-h-screen bg-brand-50 pb-24 animate-in fade-in slide-in-from-bottom-4 duration-500 font-sans">
      <div className="bg-brand-50 px-5 pt-12 pb-6">
        <div className="flex items-center mb-6">
          <button 
            onClick={onReset}
            className="p-2 -ml-2 text-slate-400 hover:text-slate-600 rounded-full hover:bg-white/50 transition-colors"
          >
            <ArrowLeft size={24} />
          </button>
          <h2 className="text-xl font-extrabold ml-2 text-slate-800 tracking-tight">견적 분석 결과</h2>
        </div>
        
        <div className="bg-white p-5 rounded-[24px] flex items-start gap-4 border border-brand-100 shadow-sm">
          <div className="mt-1 shrink-0">
             <Mascot type="success" className="w-14 h-14" />
          </div>
          <div>
            <h3 className="font-bold text-brand-600 text-sm mb-1 flex items-center gap-2">
              분석이 완료되었어요!
            </h3>
            <p className="text-sm text-slate-600 leading-relaxed font-medium break-keep">
              {data.summary}
            </p>
          </div>
        </div>
      </div>

      <div className="p-5 space-y-6">
        {/* Total Cost Card */}
        <div className="bg-white rounded-[32px] p-6 shadow-sm border border-slate-100">
          <span className="text-slate-400 text-sm font-bold ml-1">총 예상 수리비</span>
          <div className="flex items-baseline gap-1 mt-2 mb-4 ml-1">
            <h1 className="text-3xl font-black text-slate-800 tracking-tight">
              {formatCurrency(data.totalCost)}
            </h1>
            <span className="text-sm text-slate-400 font-bold">원</span>
          </div>
          
          <div className="h-48 w-full bg-slate-50 rounded-3xl p-4 border border-slate-50">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={chartData}
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={70}
                  paddingAngle={6}
                  dataKey="value"
                  cornerRadius={6}
                >
                  {chartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} strokeWidth={0} />
                  ))}
                </Pie>
                <Tooltip 
                  formatter={(value: number) => formatCurrency(value)}
                  contentStyle={{ 
                    borderRadius: '16px', 
                    border: 'none', 
                    boxShadow: '0 10px 30px -5px rgba(0,0,0,0.1)',
                    fontFamily: 'Nunito, sans-serif',
                    fontWeight: 600,
                    padding: '12px 16px'
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Parts List */}
        <div>
          <h3 className="text-lg font-bold text-slate-800 mb-4 px-2">상세 수리 항목</h3>
          <div className="space-y-3">
            {data.parts.length === 0 ? (
               <div className="text-center p-10 text-slate-400 bg-white rounded-[32px] border border-slate-100 border-dashed flex flex-col items-center">
                 <Wrench size={32} className="mb-3 opacity-30" />
                 <p className="font-bold text-sm">수리할 항목이 발견되지 않았어요.</p>
               </div>
            ) : (
              data.parts.map((part, idx) => (
                <div key={idx} className="bg-white p-5 rounded-[24px] shadow-sm border border-slate-100 flex justify-between items-start gap-4 transition-transform hover:scale-[1.01]">
                   <div className={`mt-1.5 w-3 h-3 rounded-full shrink-0 shadow-sm ${
                      part.severity === 'high' ? 'bg-red-400 shadow-red-200' : 
                      part.severity === 'medium' ? 'bg-orange-300 shadow-orange-100' : 'bg-green-300 shadow-green-100'
                    }`} />
                  <div className="flex-1">
                    <div className="flex justify-between items-center mb-1">
                      <h4 className="font-bold text-slate-700 text-[15px]">{part.name}</h4>
                      <span className="text-brand-600 font-extrabold text-[15px]">{formatCurrency(part.cost)}</span>
                    </div>
                    <p className="text-xs text-slate-400 mb-3 font-medium">{part.description}</p>
                    <span className={`inline-flex px-2.5 py-1 rounded-lg text-[10px] font-bold tracking-wide
                      ${part.severity === 'high' ? 'bg-red-50 text-red-500' : 
                        part.severity === 'medium' ? 'bg-orange-50 text-orange-500' : 'bg-green-50 text-green-600'}
                    `}>
                      {part.severity === 'high' ? '심각함' : part.severity === 'medium' ? '주의필요' : '경미함'}
                    </span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        <button 
          onClick={onReset}
          className="w-full bg-slate-800 hover:bg-slate-700 text-white font-bold py-4 rounded-[20px] transition-all shadow-lg shadow-slate-200 flex items-center justify-center gap-2 transform active:scale-[0.98]"
        >
          <RefreshCw size={18} />
          다른 사진도 확인하기
        </button>

        <p className="text-[11px] text-slate-400 text-center leading-normal px-4 pb-4">
          <AlertTriangle size={12} className="inline mr-1 mb-0.5" />
          위 견적은 AI 예상 결과이며 실제 수리비와 차이가 있을 수 있습니다. <br/>정확한 비용은 가까운 정비소에서 확인해주세요.
        </p>
      </div>
    </div>
  );
};