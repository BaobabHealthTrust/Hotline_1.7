var content = document.getElementById('content');

function showHelpButton(){
    imgCircle = document.getElementById('img-circle');
    if (imgCircle) imgCircle.parentNode.removeChild(imgCircle);

    imgCircle = document.createElement('div');
    imgCircle.id = 'img-circle';
    imgCircle.style.position = 'relative';
    imgCircle.style.zIndex = '900';
    imgCircle.style.borderRadius = '50%';
    imgCircle.style.width = '50px';
    imgCircle.style.cursor = 'pointer';
    imgCircle.style.top = '0px';
    imgCircle.style.float = 'right';
    imgCircle.style.right = '1%';
    imgCircle.style.height = '50px';
    imgCircle.style.background = "#f3f3f3 url('/assets/icons/info-sign.png') no-repeat center";
    imgCircle.style.boxShadow = '0 0 8px rgba(0, 0, 0, .8)';
    imgCircle.style.backgroundSize = "60px 60px";

    imgCircle.onclick = function(){
        showLibPopup();
    }

    img = document.createElement('img');
    imgCircle.appendChild(img);
    content.appendChild(imgCircle);
}

function hideHelpButton(){
    imgCircle = document.getElementById('img-circle');
    if (imgCircle) imgCircle.parentNode.removeChild(imgCircle);
}

function showLibPopup(){
    popupDiv = document.createElement('div');
    popupDiv.className = 'popup-div';
    popupDiv.style.backgroundColor = '#F4F4F4';
    popupDiv.style.border = '2px solid #E0E0E0';
    popupDiv.style.borderRadius = '15px';
    popupDiv.style.height = (0.65*screen.height) + "px";
    popupDiv.style.padding = '5px';
    popupDiv.style.top = "-5vh";
    popupDiv.style.position = 'absolute';
    popupDiv.style.marginTop = '70px';
    popupDiv.style.width = (0.85*screen.width) + "px";
    popupDiv.style.marginLeft = (0.05*screen.width) + "px";
    popupDiv.style.zIndex = '1022';
    content.appendChild(popupDiv);

    popupHeader = document.createElement('div');
    popupHeader.className = 'popup-header';
    popupHeader.innerHTML = 'Data';
    popupHeader.style.borderBottom = '2px solid #7D9EC0';
    popupHeader.style.marginLeft = '-5px';
    popupHeader.style.width = '101%';
    popupHeader.style.backgroundColor = '#FFFFFF';
    popupHeader.style.marginTop = '-5px';
    popupHeader.style.paddingTop = '5px';
    popupHeader.style.borderRadius = '15px 15px 0 0';
    popupHeader.style.fontSize = '14pt';
    popupHeader.style.fontWeight = 'bolder';


    popupDiv.appendChild(popupHeader);
    popupData = document.createElement('div');
    popupData.className = 'popup-data';
    popupData.innerHTML = 'Your data goes here<br /><br /><br />'
    popupDiv.appendChild(popupData);
    popupFooter = document.createElement('div');
    popupFooter.className = 'popup-footer';
    popupFooter.style.position = 'absolute';
    popupFooter.style.marginBottom = '60px';

    okaySpan = document.createElement('span');
    okaySpan.className = 'prevButton';
    okaySpan.innerHTML = '<< Prev Article';
    okaySpan.style.backgroundImage = 'none';
    okaySpan.style.border = '1px solid transparent';
    okaySpan.style.borderRadius = '4px';
    okaySpan.style.cursor = 'pointer';
    okaySpan.style.display = 'inline-block';
    okaySpan.style.fontSize = '16px';
    okaySpan.style.fontWeight = 'bolder';
    okaySpan.style.lineHeight = '1.94857';
    okaySpan.style.position = 'absolute';
    okaySpan.style.bottom = '10px';
    okaySpan.style.padding = '6px 30px';
    okaySpan.style.textAlign = 'center';
    okaySpan.style.verticalAlign = 'middle';
    okaySpan.style.whiteSpace = 'nowrap';
    okaySpan.style.backgroundColor = 'gray';
    okaySpan.style.borderColor = '#2e6da4';
    okaySpan.style.color = '#fff';
    
    okaySpan.onclick = function(){
        /*popupCover = document.getElementsByClassName("popup-cover")[0];
        popupDiv = document.getElementsByClassName("popup-div")[0];
        if (popupCover) popupCover.parentNode.removeChild(popupCover);
        if (popupDiv) popupDiv.parentNode.removeChild(popupDiv);*/
        loadPrevArticle()
    }
    popupDiv.appendChild(okaySpan);

    //prev article//

    prevSpan = document.createElement('span');
    prevSpan.className = 'nextButton';
    prevSpan.innerHTML = 'Next Article  >>';
    prevSpan.style.backgroundImage = 'none';
    prevSpan.style.border = '1px solid transparent';
    prevSpan.style.borderRadius = '4px';
    prevSpan.style.cursor = 'pointer';
    prevSpan.style.display = 'inline-block';
    prevSpan.style.fontSize = '16px';
    prevSpan.style.fontWeight = 'bolder';
    prevSpan.style.lineHeight = '1.94857';
    prevSpan.style.position = 'absolute';
    prevSpan.style.bottom = '10px';
    prevSpan.style.padding = '6px 30px';
    prevSpan.style.textAlign = 'center';
    prevSpan.style.verticalAlign = 'middle';
    prevSpan.style.whiteSpace = 'nowrap';
    prevSpan.style.backgroundColor = '#6495ED';
    prevSpan.style.borderColor = '#2e6da4';
    prevSpan.style.color = '#fff';
    prevSpan.style.left = '22.6%';
    prevSpan.onclick = function(){
        /*popupCover = document.getElementsByClassName("popup-cover")[0];
        popupDiv = document.getElementsByClassName("popup-div")[0];
        if (popupCover) popupCover.parentNode.removeChild(popupCover);
        if (popupDiv) popupDiv.parentNode.removeChild(popupDiv);*/
        loadNextArticle();
    }

    popupDiv.appendChild(prevSpan);


    //START cancel Button article
    cancelSpan = document.createElement('span');
    cancelSpan.className = 'cancelButton';
    cancelSpan.innerHTML = 'Cancel';
    cancelSpan.style.backgroundImage = 'none';
    cancelSpan.style.border = '1px solid transparent';
    cancelSpan.style.borderRadius = '4px';
    cancelSpan.style.cursor = 'pointer';
    cancelSpan.style.display = 'inline-block';
    cancelSpan.style.fontSize = '16px';
    cancelSpan.style.fontWeight = 'bolder';
    cancelSpan.style.lineHeight = '1.94857';
    cancelSpan.style.position = 'absolute';
    cancelSpan.style.bottom = '10px';
    cancelSpan.style.padding = '6px 30px';
    cancelSpan.style.textAlign = 'center';
    cancelSpan.style.verticalAlign = 'middle';
    cancelSpan.style.whiteSpace = 'nowrap';
    cancelSpan.style.backgroundColor = '#EE6363';
    cancelSpan.style.borderColor = '#2e6da4';
    cancelSpan.style.color = '#fff';
    cancelSpan.style.left = '90%';
    cancelSpan.onclick = function(){
        popupCover = document.getElementsByClassName("popup-cover")[0];
        popupDiv = document.getElementsByClassName("popup-div")[0];
        if (popupCover) popupCover.parentNode.removeChild(popupCover);
        if (popupDiv) popupDiv.parentNode.removeChild(popupDiv);
    }

    popupDiv.appendChild(cancelSpan);
    //END cancel Button


    popupDiv.appendChild(popupFooter);

    popupCover = document.createElement('div');
    popupCover.className = 'popup-cover';
    popupCover.style.position = 'absolute';
    popupCover.style.backgroundColor = 'black';
    popupCover.style.width = '100%';
    popupCover.style.height = '102%';
    popupCover.style.left = '0%';
    popupCover.style.top = '0%';
    popupCover.style.zIndex = '990';
    popupCover.style.opacity = '0.65';
    content.appendChild(popupCover);

    loadArticles();
}