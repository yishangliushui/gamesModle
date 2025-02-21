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
// ==/UserScript==

(function() {
  'use strict';

  // 签到主函数
  const doSign = function (kaptcha){
    // 构造请求参数
    const params = new URLSearchParams();
    params.append('kaptcha', kaptcha);
    // 发送签到请求
    GM_xmlhttpRequest({
      method: "POST",
      url: "https://toolshu.com/user/sign",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Origin": "https://toolshu.com/user/sign",
        "Referer": "https://toolshu.com/user/sign"
      },
      data: params.toString(),
      responseType: "json", // 获取原始字节数据
      onload: function(response) {
        console.log('响应数据:', response.response);
        if (response.status !== 200) {
          console.error("请求失败，状态码:", response.status);
          return;
        }
        // 解析响应数据
        const responseData = response.response; // 响应数据是 JSON 对象
        const dataValue = responseData.data;
        if (200 !== dataValue){
          alert("土薯脚本已成功运行！结果为：签到失败：" + dataValue)
        } else {
          alert("土薯脚本已成功运行！结果为：签到成功")

        }
      },
      onerror: function(error) {
        alert("土薯脚本已成功运行！结果为：请求失败：" + error)
      }
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
        });
      },

      onerror: function (error) {
        console.error('错误:', error);
      }
    });
  };


  // 在页面加载完成后执行签到
  window.addEventListener('load', () => {
    const today = new Date().toDateString();
    console.log('页面加载完成，开始自动土薯签到...');
    const lastSignToolShuWindow = GM_getValue('lastSignToolShuWindow', '');
    if (lastSignToolShuWindow !== today) {

      getImage();

      setTimeout(()=> {
        const lastSignToolShuWindow = GM_getValue('toolShuBase64String', '');
        getImageCode(lastSignToolShuWindow)
      }, 3000)


      setTimeout(()=> {
        const kaptcha = GM_getValue('kaptcha', '');
        doSign(kaptcha)
      }, 6000)
    }
  });
})();