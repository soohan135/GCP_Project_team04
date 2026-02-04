import React, { useState, useRef } from 'react';
import { Header } from './components/Header';
import { BottomNav } from './components/BottomNav';
import { ResultView } from './components/ResultView';
import { QuotePreview } from './components/QuotePreview';
import { GarageResponse } from './components/GarageResponse';
import { ChatList } from './components/ChatList';
import { NearbyGarages } from './components/NearbyGarages';
import { analyzeCarDamage } from './services/geminiService';
import { AppState, DamageEstimate, Tab } from './types';
import { Plus, Image as ImageIcon, Camera } from 'lucide-react';
import { Mascot } from './components/Mascot';
import clsx from 'clsx';

function App() {
  const [activeTab, setActiveTab] = useState<Tab>('home');
  const [appState, setAppState] = useState<AppState>(AppState.IDLE);
  const [estimateData, setEstimateData] = useState<DamageEstimate | null>(null);
  const [loadingMessage, setLoadingMessage] = useState("AI가 사진을 분석하고 있어요...");
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setAppState(AppState.ANALYZING);
    setLoadingMessage("차량 손상 부위를 살펴보고 있어요!");
    
    // Simulate steps for better UX
    setTimeout(() => setLoadingMessage("수리하는데 얼마가 들지 계산 중이에요..."), 2000);
    setTimeout(() => setLoadingMessage("거의 다 됐어요! 조금만 기다려주세요."), 4500);

    try {
      const data = await analyzeCarDamage(file);
      setEstimateData(data);
      setAppState(AppState.RESULT);
    } catch (error) {
      console.error(error);
      setAppState(AppState.ERROR);
    } finally {
        // Reset file input so user can select same file again if needed
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    }
  };

  const triggerFileUpload = () => {
    fileInputRef.current?.click();
  };

  const renderContent = () => {
    if (activeTab === 'preview') {
      return <QuotePreview />;
    }

    if (activeTab === 'response') {
      return <GarageResponse />;
    }

    if (activeTab === 'chat') {
      return <ChatList />;
    }

    if (activeTab === 'map') {
      return <NearbyGarages />;
    }

    // Home Tab Content
    if (appState === AppState.RESULT && estimateData) {
      return (
        <ResultView 
          data={estimateData} 
          onReset={() => {
            setAppState(AppState.IDLE);
            setEstimateData(null);
          }} 
        />
      );
    }

    return (
      <main className="px-5 mt-4">
        {/* Hero Section */}
        <div className="text-center mb-8 animate-in fade-in slide-in-from-bottom-2 duration-700 pt-4">
          <div className="flex justify-center mb-4">
             <div className="relative">
                <div className="absolute -inset-4 bg-white/50 rounded-full blur-xl animate-pulse"></div>
                <Mascot type="idle" className="w-24 h-24 relative z-10" />
             </div>
          </div>
          <h2 className="text-[22px] font-extrabold text-slate-800 mb-2 tracking-tight">
            안녕하세요! <br/>
            <span className="text-brand-500">AI 정비사 픽시</span>가 도와드릴게요
          </h2>
          <p className="text-slate-500 text-sm font-medium leading-relaxed">
            파손된 부위 사진을 올려주시면<br/>
            빠르게 견적을 내어드려요.
          </p>
        </div>

        {/* Upload Card - Reverted to White */}
        <div className="bg-white rounded-[32px] p-8 border border-slate-100 flex flex-col items-center justify-center min-h-[380px] relative overflow-hidden transition-all shadow-sm">
          
          {appState === AppState.ANALYZING ? (
             <div className="absolute inset-0 bg-white/95 z-20 flex flex-col items-center justify-center p-6 text-center animate-in fade-in duration-300 backdrop-blur-sm">
               <div className="relative mb-8">
                 <div className="absolute inset-0 bg-brand-50 rounded-full blur-2xl opacity-60 animate-pulse"></div>
                 <Mascot type="thinking" className="w-32 h-32 relative z-10" />
               </div>
               <h3 className="text-lg font-bold text-slate-800 mb-2">{loadingMessage}</h3>
               <p className="text-sm text-slate-400 font-medium">잠시만 기다려주세요</p>
             </div>
          ) : null}

          {appState === AppState.ERROR && (
             <div className="absolute inset-0 bg-white/95 z-20 flex flex-col items-center justify-center p-6 text-center animate-in fade-in backdrop-blur-sm">
               <div className="mb-6">
                 <Mascot type="error" className="w-32 h-32" />
               </div>
               <h3 className="text-lg font-bold text-slate-800 mb-2">어라? 뭔가 잘못되었어요</h3>
               <p className="text-sm text-slate-400 mb-6 font-medium">사진을 다시 확인하거나<br/>잠시 후 다시 시도해 주세요.</p>
               <button 
                onClick={() => setAppState(AppState.IDLE)}
                className="bg-brand-500 hover:bg-brand-600 text-white px-8 py-3 rounded-2xl font-bold text-sm transition-all shadow-lg shadow-brand-200 transform hover:scale-105"
               >
                 다시 시도하기
               </button>
             </div>
          )}

          <div 
            onClick={triggerFileUpload}
            className={clsx(
              "group w-full h-full flex flex-col items-center justify-center cursor-pointer transition-transform duration-300 hover:scale-[1.02]",
              appState !== AppState.IDLE && "opacity-0 pointer-events-none"
            )}
          >
            <div className="relative mb-8">
               <div className="absolute inset-0 bg-brand-50 rounded-full blur-lg opacity-40 group-hover:opacity-80 transition-opacity duration-500"></div>
               <div className="bg-brand-50 group-hover:bg-brand-100 border-2 border-brand-100 group-hover:border-brand-200 w-28 h-28 rounded-[2rem] flex items-center justify-center transition-all duration-300 shadow-sm group-hover:shadow-md">
                 <Plus size={48} className="text-brand-300 group-hover:text-brand-500 transition-colors duration-300" strokeWidth={3.5} />
               </div>
               <div className="absolute -top-2 -right-2 bg-brand-500 text-white text-[10px] font-bold px-2 py-1 rounded-full shadow-md animate-bounce">
                  TOUCH!
               </div>
            </div>
            
            <h3 className="text-lg font-bold text-slate-700 mb-2 group-hover:text-brand-600 transition-colors">
              사진 업로드하기
            </h3>
            <p className="text-sm text-slate-400 mb-8 font-medium">
              여기를 눌러서 사진을 선택하세요
            </p>

            <div className="flex gap-3">
                <div className="bg-brand-50 group-hover:bg-brand-100 px-5 py-2.5 rounded-2xl flex items-center gap-2 text-xs font-bold text-brand-600 group-hover:text-brand-700 border border-brand-100 group-hover:border-brand-200 transition-all shadow-sm">
                    <Camera size={16} />
                    <span>카메라</span>
                </div>
                 <div className="bg-brand-50 group-hover:bg-brand-100 px-5 py-2.5 rounded-2xl flex items-center gap-2 text-xs font-bold text-brand-600 group-hover:text-brand-700 border border-brand-100 group-hover:border-brand-200 transition-all shadow-sm">
                    <ImageIcon size={16} />
                    <span>갤러리</span>
                </div>
            </div>
          </div>
          
          <input 
            type="file" 
            accept="image/*" 
            className="hidden" 
            ref={fileInputRef}
            onChange={handleFileChange}
          />
        </div>
      </main>
    );
  };

  return (
    <div className="min-h-screen bg-brand-50 pb-40 font-sans selection:bg-brand-100">
      <Header />
      {renderContent()}
      <BottomNav activeTab={activeTab} onTabChange={setActiveTab} />
    </div>
  );
}

export default App;