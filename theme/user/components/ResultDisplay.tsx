import React from 'react';
import { EstimateResult } from '../types';
import { ArrowLeft, Wrench, CheckCircle, RefreshCw } from 'lucide-react';
import { Mascot } from './Mascot';

interface ResultDisplayProps {
  result: EstimateResult;
  imageSrc: string;
  onReset: () => void;
}

export const ResultDisplay: React.FC<ResultDisplayProps> = ({ result, imageSrc, onReset }) => {
  return (
    <div className="h-full overflow-y-auto pb-24 px-6 pt-2">
      {/* Top Nav */}
      <button 
        onClick={onReset}
        className="mb-4 flex items-center text-slate-500 hover:text-sky-600 transition-colors font-bold text-sm"
      >
        <ArrowLeft size={18} className="mr-1" /> 처음으로
      </button>

      {/* Mascot Message */}
      <Mascot message={result.funFact} expression="happy" />

      {/* Main Card */}
      <div className="bg-white rounded-[2.5rem] shadow-xl shadow-sky-100 overflow-hidden border border-sky-50">
        
        {/* Image Preview with overlay */}
        <div className="relative h-48 w-full">
          <img src={imageSrc} alt="Analysis" className="w-full h-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent flex items-end p-6">
            <span className="text-white font-bold text-lg cute-font">분석 완료!</span>
          </div>
        </div>

        <div className="p-6 space-y-6">
          {/* Analysis Summary */}
          <div>
             <h4 className="text-sm font-bold text-sky-500 uppercase tracking-wider mb-2 flex items-center gap-2">
               <CheckCircle size={16} /> 손상 진단
             </h4>
             <p className="text-slate-700 font-medium leading-relaxed">
               {result.damageAnalysis}
             </p>
          </div>

          {/* Cost Estimate Box */}
          <div className="bg-sky-50 rounded-2xl p-5 border border-sky-100">
            <h4 className="text-xs text-slate-500 font-bold mb-1">예상 수리 비용</h4>
            <div className="flex items-baseline gap-1">
              <span className="text-2xl font-bold text-sky-600 cute-font">
                {result.estimatedCostMin.toLocaleString()}
              </span>
              <span className="text-slate-400">~</span>
              <span className="text-2xl font-bold text-sky-600 cute-font">
                {result.estimatedCostMax.toLocaleString()}
              </span>
              <span className="text-sm text-slate-600 font-medium">원</span>
            </div>
            <p className="text-[10px] text-slate-400 mt-2">* 실제 견적은 정비소마다 다를 수 있어요.</p>
          </div>

          {/* Repair Steps */}
          <div>
            <h4 className="text-sm font-bold text-slate-800 mb-3 flex items-center gap-2">
               <Wrench size={16} className="text-orange-400" /> 수리 과정
             </h4>
            <ul className="space-y-3">
              {result.repairSteps.map((step, idx) => (
                <li key={idx} className="flex items-start gap-3 text-sm text-slate-600">
                  <span className="flex-shrink-0 w-6 h-6 bg-orange-100 text-orange-500 rounded-full flex items-center justify-center font-bold text-xs mt-0.5">
                    {idx + 1}
                  </span>
                  <span className="pt-0.5 leading-relaxed">{step}</span>
                </li>
              ))}
            </ul>
          </div>

          <button 
            onClick={onReset}
            className="w-full py-4 bg-slate-800 text-white rounded-2xl font-bold shadow-lg hover:bg-slate-700 transition-all flex items-center justify-center gap-2"
          >
            <RefreshCw size={18} /> 다른 사진 분석하기
          </button>
        </div>
      </div>
    </div>
  );
};
