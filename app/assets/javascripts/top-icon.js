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
    popupDiv.style.height = '522px';
    popupDiv.style.padding = '5px';
    popupDiv.style.position = 'absolute';
    popupDiv.style.marginTop = '70px';
    popupDiv.style.width = '1217px';
    popupDiv.style.marginLeft = '172px';
    popupDiv.style.zIndex = '991';
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
    okaySpan.className = 'okay-button';
    okaySpan.innerHTML = 'Okay';
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
    okaySpan.style.padding = '6px 56px';
    okaySpan.style.textAlign = 'center';
    okaySpan.style.verticalAlign = 'middle';
    okaySpan.style.whiteSpace = 'nowrap';
    okaySpan.style.backgroundColor = '#6495ED';
    okaySpan.style.borderColor = '#2e6da4';
    okaySpan.style.left = '0px';
    okaySpan.style.color = '#fff';
    okaySpan.style.width = '90.6%';
    okaySpan.onclick = function(){
        popupCover = document.getElementsByClassName("popup-cover")[0];
        popupDiv = document.getElementsByClassName("popup-div")[0];
        if (popupCover) popupCover.parentNode.removeChild(popupCover);
        if (popupDiv) popupDiv.parentNode.removeChild(popupDiv);
    }
    //popupFooter.appendChild(okaySpan);
    popupDiv.appendChild(okaySpan);
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
}