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
    // Auto clear error after 3 seconds
    setTimeout(() => setErrorMsg(null), 3000);
  };

  const handleReset = () => {
    setResult(null);
    setUploadedImage(null);
    setCurrentView(AppView.HOME);
  };

  return (
    <div className="relative h-screen flex flex-col max-w-md mx-auto bg-gradient-to-br from-sky-200 via-sky-50 to-white shadow-2xl overflow-hidden">
      
      {/* Decorative Background Elements */}
      <div className="absolute top-[-10%] right-[-10%] w-64 h-64 bg-white/20 rounded-full blur-3xl pointer-events-none"></div>
      <div className="absolute bottom-[20%] left-[-20%] w-80 h-80 bg-sky-300/10 rounded-full blur-3xl pointer-events-none"></div>

      <Header />

      <main className="flex-1 flex flex-col relative z-0 overflow-hidden">
        
        {/* Search Bar (Only visible on Home) */}
        {currentView === AppView.HOME && !result && (
          <div className="px-6 mb-4">
            <div className="bg-white/70 backdrop-blur-sm p-1 rounded-2xl shadow-sm border border-white flex items-center pl-4">
              <Search className="text-slate-400" size={20} />
              <input 
                type="text" 
                placeholder="정비소, 서비스 검색..." 
                className="bg-transparent border-none outline-none p-3 w-full text-slate-700 placeholder-slate-400"
              />
            </div>
          </div>
        )}

        {/* Loading State */}
        {isAnalyzing && (
          <div className="absolute inset-0 z-50 flex flex-col items-center justify-center bg-white/80 backdrop-blur-sm">
             <Mascot message="열심히 분석 중이에요..." expression="thinking" />
             <div className="mt-8 flex space-x-2">
               <div className="w-3 h-3 bg-sky-500 rounded-full animate-bounce"></div>
               <div className="w-3 h-3 bg-sky-500 rounded-full animate-bounce [animation-delay:-0.15s]"></div>
               <div className="w-3 h-3 bg-sky-500 rounded-full animate-bounce [animation-delay:-0.3s]"></div>
             </div>
          </div>
        )}

        {/* Error Toast */}
        {errorMsg && (
          <div className="absolute top-4 left-6 right-6 z-50 bg-red-400 text-white p-4 rounded-2xl shadow-lg flex items-center justify-center animate-bounce-slow">
            <span className="font-bold text-sm">{errorMsg}</span>
          </div>
        )}

        {/* Views */}
        <div className="flex-1 overflow-y-auto scrollbar-hide">
          {currentView === AppView.HOME && (
            <>
              <div className="px-6 py-4 text-center">
                <h2 className="text-3xl font-bold text-slate-800 mb-2 cute-font">AI 기반 자동 견적</h2>
                <p className="text-slate-500 text-sm leading-relaxed">
                  사진만 올리면 끝! <br/>
                  귀여운 AI 로봇이 즉시 견적을 알려드려요.
                </p>
              </div>

              <div className="mt-4">
                <Mascot message="안녕하세요! 오늘 차 상태는 어떤가요?" />
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
              <Mascot message="아직 준비 중인 기능이에요!" expression="waiting" />
              <button 
                onClick={() => setCurrentView(AppView.HOME)}
                className="mt-6 px-6 py-2 bg-sky-100 text-sky-600 rounded-full font-bold text-sm hover:bg-sky-200 transition"
              >
                홈으로 가기
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
