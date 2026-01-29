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
      onError('이미지 파일만 부탁해!');
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
        onError('오류가 발생했어. 다시 시도해줘!');
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
          bg-white rounded-3xl
          border-[3px] border-dashed transition-all duration-300
          flex flex-col items-center justify-center p-8 group cursor-pointer
          ${dragActive ? 'border-brand-500 bg-brand-50 scale-105' : 'border-slate-200 hover:border-brand-300'}
        `}
        onDragEnter={handleDrag}
        onDragLeave={handleDrag}
        onDragOver={handleDrag}
        onDrop={handleDrop}
        onClick={() => fileInputRef.current?.click()}
      >
        <div className="bg-brand-100 p-5 rounded-2xl mb-6 group-hover:rotate-12 transition-transform duration-300 border-2 border-brand-200">
          <Upload className="text-brand-600" size={42} strokeWidth={2.5} />
        </div>
        
        <h3 className="text-xl font-bold text-slate-800 mb-2 text-center brand-font">
          어디가 아픈가요?
        </h3>
        <p className="text-sm text-slate-400 text-center mb-6">
          사진을 탭하거나 끌어와주세요!
        </p>

        <div className="flex gap-3 w-full">
           <button className="flex-1 bg-slate-100 hover:bg-slate-200 py-3 rounded-xl flex items-center justify-center gap-2 text-slate-600 font-bold text-sm transition-colors border-2 border-transparent hover:border-slate-300">
             <ImageIcon size={18} /> 앨범
           </button>
           <button className="flex-1 bg-brand-500 hover:bg-brand-600 py-3 rounded-xl flex items-center justify-center gap-2 text-white font-bold text-sm shadow-[2px_2px_0px_0px_rgba(30,41,59,1)] transition-transform active:translate-y-[2px] active:shadow-none border-2 border-slate-800">
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