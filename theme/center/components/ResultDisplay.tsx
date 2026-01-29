import React from 'react';
import { EstimateResult } from '../types';
import { ArrowLeft, Wrench, CheckCircle, RefreshCw, TriangleAlert } from 'lucide-react';
import { Mascot } from './Mascot';

interface ResultDisplayProps {
  result: EstimateResult;
  imageSrc: string;
  onReset: () => void;
}

export const ResultDisplay: React.FC<ResultDisplayProps> = ({ result, imageSrc, onReset }) => {
  return (
    <div className="h-full overflow-y-auto pb-32 px-6 pt-2">
      {/* Top Nav */}
      <button 
        onClick={onReset}
        className="mb-4 flex items-center text-slate-500 hover:text-brand-600 transition-colors font-bold text-sm bg-white px-3 py-1 rounded-full border border-slate-200 shadow-sm"
      >
        <ArrowLeft size={16} className="mr-1" /> 처음으로
      </button>

      {/* Mascot Message */}
      <Mascot message={result.funFact} expression="happy" />

      {/* Main Card */}
      <div className="bg-white rounded-3xl shadow-xl overflow-hidden border-2 border-slate-100">
        
        {/* Image Preview */}
        <div className="relative h-56 w-full group">
          <img src={imageSrc} alt="Analysis" className="w-full h-full object-cover" />
          <div className="absolute bottom-0 left-0 right-0 h-16 bg-gradient-to-t from-slate-900/80 to-transparent flex items-end p-5">
             <div className="flex items-center gap-2">
               <span className="w-2 h-2 rounded-full bg-green-400 animate-pulse"></span>
               <span className="text-white font-bold text-xl brand-font tracking-wide">분석 리포트</span>
             </div>
          </div>
        </div>

        <div className="p-6 space-y-6">
          {/* Analysis Summary */}
          <div className="bg-slate-50 p-4 rounded-2xl border border-slate-100">
             <h4 className="text-sm font-bold text-slate-400 uppercase tracking-wider mb-2 flex items-center gap-2">
               <TriangleAlert size={16} className="text-brand-500" /> 진단 결과
             </h4>
             <p className="text-slate-700 font-medium leading-relaxed">
               {result.damageAnalysis}
             </p>
          </div>

          {/* Cost Estimate Box */}
          <div className="bg-brand-50 rounded-2xl p-5 border-2 border-brand-100 relative overflow-hidden">
            <div className="absolute top-0 right-0 bg-brand-200 text-brand-700 text-[10px] font-bold px-2 py-1 rounded-bl-lg">
              ESTIMATE
            </div>
            <h4 className="text-xs text-brand-600 font-bold mb-1 opacity-80">예상 수리비</h4>
            <div className="flex items-baseline gap-1 mt-1">
              <span className="text-3xl font-bold text-slate-800 brand-font tracking-tight">
                {result.estimatedCostMin.toLocaleString()}
              </span>
              <span className="text-slate-400 font-light mx-1">~</span>
              <span className="text-3xl font-bold text-slate-800 brand-font tracking-tight">
                {result.estimatedCostMax.toLocaleString()}
              </span>
              <span className="text-sm text-slate-600 font-bold">원</span>
            </div>
            <div className="mt-3 w-full bg-brand-200 h-1.5 rounded-full overflow-hidden">
               <div className="h-full bg-brand-500 w-2/3 rounded-full"></div>
            </div>
          </div>

          {/* Repair Steps */}
          <div>
            <h4 className="text-sm font-bold text-slate-800 mb-4 flex items-center gap-2">
               <Wrench size={18} className="text-slate-400" /> 수리 가이드
             </h4>
            <ul className="space-y-4">
              {result.repairSteps.map((step, idx) => (
                <li key={idx} className="flex items-start gap-4 text-sm text-slate-600">
                  <span className="flex-shrink-0 w-6 h-6 bg-slate-800 text-white rounded-lg flex items-center justify-center font-bold text-xs shadow-md">
                    {idx + 1}
                  </span>
                  <span className="pt-0.5 leading-relaxed font-medium">{step}</span>
                </li>
              ))}
            </ul>
          </div>

          <button 
            onClick={onReset}
            className="w-full py-4 bg-brand-500 text-white rounded-2xl font-bold text-lg shadow-[4px_4px_0px_0px_rgba(30,41,59,1)] border-2 border-slate-800 hover:translate-y-[2px] hover:shadow-[2px_2px_0px_0px_rgba(30,41,59,1)] transition-all flex items-center justify-center gap-2 active:shadow-none active:translate-y-[4px]"
          >
            <RefreshCw size={20} /> 새 견적 받기
          </button>
        </div>
      </div>
    </div>
  );
};