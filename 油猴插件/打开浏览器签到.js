// ==UserScript==
// @name         自动签到脚本
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  打开浏览器时自动签到
// @author       YourName
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
  const doSign = function (formhash){
    // 构造请求参数
    const params = new URLSearchParams();
    params.append('id', 'dsu_paulsign:sign');
    params.append('operation', 'qiandao');
    params.append('formhash', formhash);
    params.append('qdxq', 'ch'); // 心情参数
    params.append('qdmode', '2'); // 签到模式
    params.append('todaysay', '');
    params.append('fastreply', '1');
    console.log("获取到的formhash为：" + formhash);
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
  }

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
          console.log("decodedText=" + decodedText)
          resolve(formhashMatch ? formhashMatch[1] : null);
        }
      });
    }).then((result) => {
      console.log("______decodedText_result______：", result)
      GM_setValue('formhash', result)
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
      const today = new Date().toDateString();
      GM_setValue('lastSignWindow', today);
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
        GM_setValue('dataValue', dataValue);
        // response.response
        // {
        //   "code": 200,
        //   "data": "Ceek",
        //   "msg": "识别完成",
        //   "remaining_calls_today": 95,
        //   "success": true
        // }
      },
      onerror: function (error) {
        console.error('错误:', error);
      }
    });
  }


  const getImage = function (formhash) {
    console.log('请求的 formhash:', formhash);
    GM_xmlhttpRequest({
      method: "GET",
      url: "https://www.tangguo2.com/misc.php?mod=seccode&update=66863&idhash=" + formhash,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Origin": "https://www.tangguo2.com",
        "Referer": "https://www.tangguo2.com/misc.php"
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
        const blob = new Blob([response.response], { type: 'image/png' });

        // 将 Blob 转换为 Base64 字符串
        const base64StringPromise = new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.onloadend = () => resolve(reader.result); // 获取完整的 Base64 数据 URL
          reader.onerror = reject;
          reader.readAsDataURL(blob);
        });

        console.log("base64StringPromise:", base64StringPromise);
        // setTimeout(() => {}, 5000);
        base64StringPromise.then((result) => {
          console.log("______result______：", result)
          if (result === "data:image/png;base64,QWNjZXNzIERlbmllZA=="){
            alert("脚本已成功运行！结果为：获取验证码失败")
            return;
          }
          GM_setValue('base64String', result);
        });
      },
      onerror: function (error) {
        console.error('错误:', error);
      }
    });
  };

  const doComment = function (dataValue){
    // 构造请求参数
    const params = new URLSearchParams();
    params.append('id', 'dsu_paulsign:sign');
    params.append('operation', 'qiandao');
    // params.append('formhash', formhash);
    params.append('qdxq', 'ch'); // 心情参数
    params.append('qdmode', '2'); // 签到模式
    params.append('todaysay', '');
    params.append('fastreply', '1');

    // 发送签到请求
    GM_xmlhttpRequest({
      method: "POST",
      url: "https://www.tangguo2.com/forum.php?mod=post&action=reply&fid=54&tid=7139&extra=page%3D1&replysubmit=yes&infloat=yes&handlekey=fastpost&inajax=1",
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
  }

  // 在页面加载完成后执行签到
  window.addEventListener('load', () => {
    const today = new Date().toDateString();
    console.log('页面加载完成，开始自动签到...');
    const lastSignWindow = GM_getValue('lastSignWindow', '');
    getFormhash();;
    if (lastSignWindow !== today) {
      setTimeout(()=> {
        // 先获取formhash（动态获取更安全）
        const formhash = GM_getValue('formhash', '')
        if (!formhash) {
          alert("脚本已成功运行！结果为：获取formhash失败")
          showNotification('获取formhash失败');
          console.log(formhash)
          return;
        }
        doSign(formhash)
      }, 3000)
    }
    // console.log('页面加载完成，开始自动评论...');
    // const lastComment = GM_getValue('lastComment', '');
    // if (lastComment !== today) {
    //   getImage(formhash);
    //   setTimeout(() => {
    //     const base64String = GM_getValue('base64String', '');
    //     if (base64String !== ""){
    //         getImageCode(base64String)
    //     }
    //     const dataValue = GM_getValue('dataValue', '');
    //     doComment(dataValue)
    //   }, 2000);
    // }
  });
})();