// ==UserScript==
// @name         自动签到脚本
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  打开浏览器时自动签到
// @author       YourName
// @match        *.bing.com/*
// @grant        GM_xmlhttpRequest
// @grant        GM_notification
// @grant        GM_getValue
// @grant        GM_setValue
// @run-at       document-start
// ==/UserScript==

(function() {
  'use strict';

  // 签到主函数
  const doSign = async () => {
    // 先获取formhash（动态获取更安全）
    const formhash = await getFormhash();
    if (!formhash) {
      alert("脚本已成功运行！结果为：获取formhash失败")
      showNotification('获取formhash失败');
      console.log(formhash)
      return;
    }

    // 构造请求参数
    const params = new URLSearchParams();
    params.append('id', 'dsu_paulsign:sign');
    params.append('operation', 'qiandao');
    params.append('formhash', formhash);
    params.append('qdxq', 'ch'); // 心情参数
    params.append('qdmode', '2'); // 签到模式
    params.append('todaysay', '');
    params.append('fastreply', '1');

    // 发送签到请求
    GM_xmlhttpRequest({
      method: "POST",
      url: "https://www.tangguo2.com/plugin.php?infloat=1&inajax=1",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Origin": "https://www.tangguo2.com",
        "Referer": "https://www.tangguo2.com/plugin.php?id=dsu_paulsign:sign"
      },
      data: params.toString(),
      responseType: "arraybuffer", // 获取原始字节数据
      onload: function(response) {
        if (response.status === 200) {
          const uint8Array = new Uint8Array(response.response);
          const decoder = new TextDecoder('gbk'); // 假设服务器返回的是 GBK 编码
          const decodedText = decoder.decode(uint8Array);
          handleResponse(decodedText);
        } else {
          showNotification('签到失败，状态码：' + response.status);
        }
      },
      onerror: function(error) {
        showNotification('请求失败：' + error);
        alert("脚本已成功运行！结果为：请求失败：" + error)
      }
    });
  };

  // 获取动态formhash
  const getFormhash = () => {
    return new Promise(resolve => {
      GM_xmlhttpRequest({
        method: "GET",
        url: "https://www.tangguo2.com/plugin.php?id=dsu_paulsign:sign",
        responseType: "arraybuffer", // 获取原始字节数据
        onload: function(response) {
          const uint8Array = new Uint8Array(response.response);
          const decoder = new TextDecoder('gbk'); // 假设服务器返回的是 GBK 编码
          const decodedText = decoder.decode(uint8Array);

          const formhashMatch = decodedText.match(/formhash=([a-f0-9]+)/);
          console.log("decodedText" + decodedText)
          console.log("decodedText" + formhashMatch)
          resolve(formhashMatch ? formhashMatch[1] : null);
        }
      });
    });
  };

  // 处理签到响应
  const handleResponse = (text) => {
    const resultMatch = text.match(/<div class="c">\s*([^<]+)\s*<\/div>/);
    // alert("脚本已成功运行！结果为：" + decodeURIComponent(encodeURIComponent(text)));
    console.log(text);
    alert("脚本已成功运行！结果为：" + resultMatch[1].trim())
    if (resultMatch) {
      showNotification(resultMatch[1].trim());
    } else if (text.includes('今日已签')) {
      showNotification('今日已完成签到');
    } else {
      showNotification('签到结果解析失败');
      GM_setValue('lastSignWindow', null);
    }
  };

  // 显示桌面通知
  const showNotification = (msg) => {
    GM_notification({
      title: '糖果社区签到',
      text: msg,
      timeout: 5000
    });
  };

  // 在页面加载完成后执行签到
  window.addEventListener('load', () => {
    console.log('页面加载完成，开始自动签到...');
    const lastSignWindow = GM_getValue('lastSignWindow', '');
    const today = new Date().toDateString();
    if (lastSignWindow !== today) {
      doSign();
      GM_setValue('lastSignWindow', today);
    }
  });
})();