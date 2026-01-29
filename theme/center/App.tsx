import React, { useState } from 'react';
import { Header } from './components/Header';
import { NavBar } from './components/NavBar';
import { UploadSection } from './components/UploadSection';
import { ResultDisplay } from './components/ResultDisplay';
import { Mascot } from './components/Mascot';
import { AppView, EstimateResult } from './types';
import { Search } from 'lucide-react';

const App: React.FC = () => {
  const [currentView, setCurrentView] = useState<AppView>(AppView.HOME);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [result, setResult] = useState<EstimateResult | null>(null);
  const [uploadedImage, setUploadedImage] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleAnalyzeStart = () => {
    setIsAnalyzing(true);
    setErrorMsg(null);
  };

  const handleAnalyzeComplete = (res: EstimateResult, imageSrc: string) => {
    setIsAnalyzing(false);
    setResult(res);
    setUploadedImage(imageSrc);
    setCurrentView(AppView.ESTIMATE);
  };

  const handleError = (msg: string) => {
    setIsAnalyzing(false);
    setErrorMsg(msg);
    setTimeout(() => setErrorMsg(null), 3000);
  };

  const handleReset = () => {
    setResult(null);
    setUploadedImage(null);
    setCurrentView(AppView.HOME);
  };

  return (
    <div className="relative h-screen flex flex-col max-w-md mx-auto bg-[#fff7ed] shadow-2xl overflow-hidden">
      
      {/* Decorative Background Blobs */}
      <div className="absolute top-[-5%] right-[-20%] w-72 h-72 bg-brand-200/40 rounded-full blur-3xl pointer-events-none mix-blend-multiply"></div>
      <div className="absolute bottom-[10%] left-[-10%] w-64 h-64 bg-yellow-200/40 rounded-full blur-3xl pointer-events-none mix-blend-multiply"></div>

      <Header />

      <main className="flex-1 flex flex-col relative z-0 overflow-hidden">
        
        {/* Search Bar */}
        {currentView === AppView.HOME && !result && (
          <div className="px-6 mb-2">
            <div className="bg-white p-1 rounded-xl shadow-sm border border-brand-100 flex items-center pl-4 focus-within:ring-2 ring-brand-200 transition-all">
              <Search className="text-brand-300" size={20} />
              <input 
                type="text" 
                placeholder="어떤 도움이 필요하신가요?" 
                className="bg-transparent border-none outline-none p-3 w-full text-slate-700 placeholder-slate-400 font-medium"
              />
            </div>
          </div>
        )}

        {/* Loading State */}
        {isAnalyzing && (
          <div className="absolute inset-0 z-50 flex flex-col items-center justify-center bg-white/90 backdrop-blur-sm">
             <Mascot message="Bolt가 열심히 분석하고 있어요!" expression="thinking" />
             <div className="mt-8 flex space-x-3">
               <div className="w-4 h-4 bg-brand-500 rounded-sm animate-bounce"></div>
               <div className="w-4 h-4 bg-slate-800 rounded-sm animate-bounce [animation-delay:-0.15s]"></div>
               <div className="w-4 h-4 bg-brand-500 rounded-sm animate-bounce [animation-delay:-0.3s]"></div>
             </div>
          </div>
        )}

        {/* Error Toast */}
        {errorMsg && (
          <div className="absolute top-4 left-6 right-6 z-50 bg-red-500 text-white p-4 rounded-xl shadow-xl flex items-center justify-center animate-bounce-slow border-2 border-red-700">
            <span className="font-bold text-sm">{errorMsg}</span>
          </div>
        )}

        {/* Views */}
        <div className="flex-1 overflow-y-auto scrollbar-hide">
          {currentView === AppView.HOME && (
            <>
              <div className="px-6 py-6 text-center">
                <h2 className="text-4xl text-slate-800 mb-2 brand-font leading-tight">
                  <span className="text-brand-500">스마트</span>한<br/>차량 진단
                </h2>
                <p className="text-slate-500 text-sm font-medium">
                  사진 한 장으로 견적부터 수리 방법까지<br/>
                  Bolt에게 물어보세요!
                </p>
              </div>

              <div className="mt-2">
                <Mascot message="준비 완료! 시동 걸어볼까요?" />
                <UploadSection 
                  onAnalyzeStart={handleAnalyzeStart}
                  onAnalyzeComplete={handleAnalyzeComplete}
                  onError={handleError}
                />
              </div>
            </>
          )}

          {currentView === AppView.ESTIMATE && result && uploadedImage && (
            <ResultDisplay 
              result={result} 
              imageSrc={uploadedImage} 
              onReset={handleReset} 
            />
          )}

          {(currentView === AppView.CHAT || currentView === AppView.MAP) && (
            <div className="flex flex-col items-center justify-center h-[60%] text-center px-6">
              <Mascot message="곧 오픈할 예정이에요! 조금만 기다려주세요." expression="waiting" />
              <button 
                onClick={() => setCurrentView(AppView.HOME)}
                className="mt-8 px-8 py-3 bg-brand-100 text-brand-700 rounded-xl font-bold text-sm hover:bg-brand-200 transition shadow-sm"
              >
                메인으로 이동
              </button>
            </div>
          )}
        </div>
      </main>

      <NavBar currentView={currentView} setView={setCurrentView} />
    </div>
  );
};

export default App;