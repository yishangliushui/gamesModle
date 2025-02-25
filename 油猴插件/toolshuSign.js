// ==UserScript==
// @name         打开浏览器时自动签到土薯
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  打开浏览器时自动签到土薯
// @author       yishang
// @match        *.bing.com/*
// @grant        GM_notification
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_xmlhttpRequest
// @run-at       document-start
// @require      https://cdn.jsdelivr.net/npm/gifuct-js@1.0.1/build/gifuct-js.min.js
// ==/UserScript==

(function() {
  'use strict';

  // 动态加载 gifuct-js 库
  function loadGifuctJs() {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/gifuct-js@1.0.1/build/gifuct-js.min.js';
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });
  }


  const getImageCode = function (base64String){
    // 调用自动识别验证码接口
    // https://imgcode.toolshu.com/api
    console.log('请求的 base64String:', base64String);
    GM_xmlhttpRequest({
      method: "POST",
      url: "https://imgcode.toolshu.com/api",
      headers: {
        "Content-Type": "application/json",
        "Origin": "https://imgcode.toolshu.com",
        "Referer": "https://imgcode.toolshu.com/api"
      },
      data: JSON.stringify({ // 将请求体转换为 JSON 字符串
        "token": "ts_COW8RP63VYBH0PJU41ZGESC3D", // API Token
        "file": base64String // 去掉 Base64 数据的前缀
      }),
      responseType: "json", // 设置响应类型为 JSON
      onload: function (response) {
        console.log('响应数据:', response.response);
        if (response.status !== 200) {
          console.error("请求失败，状态码:", response.status);
          return;
        }

        // 解析响应数据
        const responseData = response.response; // 响应数据是 JSON 对象
        const dataValue = responseData.data;
        console.log('提取的 data 值:', dataValue);
        GM_setValue('kaptcha', dataValue);
      },
      onerror: function (error) {
        console.error('错误:', error);
      }
    });
  }


  const getImage = function () {
    GM_xmlhttpRequest({
      method: "GET",
      url: "https://toolshu.com/getKaptcha",
      headers: {
        "Origin": "https://toolshu.com/getKaptcha",
        "Referer": "https://toolshu.com/getKaptcha"
      },
      responseType: "arraybuffer",
      onload: function (response) {
        console.log('响应状态码:', response.status);
        console.log('响应头部:', response.responseHeaders);

        if (response.status !== 200) {
          console.error("请求失败，状态码:", response.status);
          return;
        }
        console.log('响应数据:', response.response);
        const blob = new Blob([response.response], { type: 'image/gif' });

        // 将 Blob 转换为 Base64 字符串
        const base64StringPromise = new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.onloadend = () => resolve(reader.result); // 获取完整的 Base64 数据 URL
          reader.onerror = reject;
          reader.readAsDataURL(blob);
        });

        console.log("toolShuBase64String:", base64StringPromise);
        // setTimeout(() => {}, 5000);
        base64StringPromise.then((result) => {
          console.log("______result______：", result)
          GM_setValue('toolShuBase64String', result);
          // 拆分为没一帧
          splitBase64GifToPng(result)
        });
      },

      onerror: function (error) {
        console.error('错误:', error);
      }
    });
  };

// 提示用户输入 Base64 格式的 GIF
  function splitBase64GifToPng(base64Gif) {
    // const base64Gif = prompt("请输入 Base64 格式的 GIF 数据:");
    // if (!base64Gif) return;
    // 确保 gifuct-js 已加载
    loadGifuctJs();

    // 解码 Base64 并提取二进制数据
    const binaryData = atob(base64Gif.split(',')[1]);
    const arrayBuffer = new ArrayBuffer(binaryData.length);
    const uint8Array = new Uint8Array(arrayBuffer);
    for (let i = 0; i < binaryData.length; i++) {
      uint8Array[i] = binaryData.charCodeAt(i);
    }

    // 使用 gifuct-js 解析 GIF
    const decoder = new GifReader(uint8Array);
    const numFrames = decoder.numFrames();


    // 创建画布以绘制每一帧
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');

    // 获取每一帧并转换为 PNG
    const frames = [];
    for (let i = 0; i < numFrames; i++) {
      const { width, height } = decoder.frameInfo(i);
      canvas.width = width;
      canvas.height = height;

      const frameData = new Uint32Array(width * height);
      decoder.decodeAndBlitFrameRGBA(i, frameData);

      const imageData = ctx.createImageData(width, height);
      imageData.data.set(new Uint8ClampedArray(frameData.buffer));
      ctx.putImageData(imageData, 0, 0);

      const pngData = canvas.toDataURL('image/png');
      frames.push(pngData);
    }

    saveFrames(frames);
  }

  // 保存每一帧为 PNG 文件
  function saveFrames(frames) {
    frames.forEach((pngData, index) => {
      const link = document.createElement('a');
      link.href = pngData;
      link.download = `frame_${index + 1}.png`;
      link.click();
    });
    alert('所有帧已保存为 PNG 文件！');
  }


  // 在页面加载完成后执行签到
  window.addEventListener('load', () => {
    const today = new Date().toDateString();
    console.log('页面加载完成，开始自动土薯签到...');
    const lastSignToolShuWindow = GM_getValue('lastSignToolShuWindow', '');
    if (lastSignToolShuWindow !== today) {

      getImage();

      // setTimeout(()=> {
      //   const lastSignToolShuWindow = GM_getValue('toolShuBase64String', '');
      //   getImageCode(lastSignToolShuWindow)
      // }, 3000)


      // setTimeout(()=> {
      //   const kaptcha = GM_getValue('kaptcha', '');
      //   doSign(kaptcha)
      // }, 6000)
    }
  });
})();