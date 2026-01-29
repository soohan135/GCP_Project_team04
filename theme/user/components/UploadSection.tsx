import React, { useRef, useState } from 'react';
import { Upload, Camera, Image as ImageIcon } from 'lucide-react';
import { analyzeCarDamage } from '../services/geminiService';
import { EstimateResult } from '../types';

interface UploadSectionProps {
  onAnalyzeStart: () => void;
  onAnalyzeComplete: (result: EstimateResult, imageSrc: string) => void;
  onError: (error: string) => void;
}

export const UploadSection: React.FC<UploadSectionProps> = ({ onAnalyzeStart, onAnalyzeComplete, onError }) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [dragActive, setDragActive] = useState(false);

  const processFile = async (file: File) => {
    if (!file.type.startsWith('image/')) {
      onError('이미지 파일만 업로드해주세요!');
      return;
    }

    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = async () => {
      const base64 = reader.result as string;
      const base64Data = base64.split(',')[1];
      
      onAnalyzeStart();
      
      try {
        const result = await analyzeCarDamage(base64Data);
        onAnalyzeComplete(result, base64);
      } catch (err) {
        onError('분석 중 오류가 발생했어요. 다시 시도해주세요.');
      }
    };
  };

  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true);
    } else if (e.type === "dragleave") {
      setDragActive(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      processFile(e.dataTransfer.files[0]);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      processFile(e.target.files[0]);
    }
  };

  return (
    <div className="w-full px-6">
      <div 
        className={`
          relative w-full aspect-square max-h-[350px] 
          bg-white rounded-[3rem] shadow-xl shadow-sky-100 
          border-4 border-dashed transition-all duration-300
          flex flex-col items-center justify-center p-8 group
          ${dragActive ? 'border-sky-400 bg-sky-50 scale-105' : 'border-sky-200 hover:border-sky-300'}
        `}
        onDragEnter={handleDrag}
        onDragLeave={handleDrag}
        onDragOver={handleDrag}
        onDrop={handleDrop}
        onClick={() => fileInputRef.current?.click()}
      >
        <div className="absolute inset-0 bg-gradient-to-br from-white/50 to-transparent rounded-[3rem] pointer-events-none"></div>
        
        <div className="bg-sky-100 p-6 rounded-full mb-6 group-hover:scale-110 transition-transform duration-300">
          <Upload className="text-sky-500" size={48} strokeWidth={2.5} />
        </div>
        
        <h3 className="text-xl font-bold text-slate-700 mb-2 text-center cute-font">
          손상된 부위를 보여주세요!
        </h3>
        <p className="text-sm text-slate-400 text-center mb-6">
          사진을 끌어오거나 터치해서 업로드
        </p>

        <div className="flex gap-3 w-full">
           <button className="flex-1 bg-slate-100 hover:bg-slate-200 py-3 rounded-2xl flex items-center justify-center gap-2 text-slate-600 font-bold text-sm transition-colors">
             <ImageIcon size={18} /> 앨범
           </button>
           <button className="flex-1 bg-sky-500 hover:bg-sky-600 py-3 rounded-2xl flex items-center justify-center gap-2 text-white font-bold text-sm shadow-lg shadow-sky-200 transition-colors">
             <Camera size={18} /> 촬영
           </button>
        </div>

        <input 
          ref={fileInputRef}
          type="file" 
          accept="image/*" 
          className="hidden" 
          onChange={handleChange}
        />
      </div>
    </div>
  );
};
