var content = document.getElementById('content');

function showHelpButton(passedConcept){
    imgCircle = document.getElementById('img-circle');
    if (imgCircle) imgCircle.parentNode.removeChild(imgCircle);

    imgWrapper = document.getElementById('img-wrapper');
    if (imgWrapper) imgWrapper.parentNode.removeChild(imgWrapper);

    imgCircle = document.createElement('img');
    imgCircle.id = "img-circle";
    imgCircle.style.borderRadius = '50%';
    imgCircle.style.width = '50px';
    imgCircle.style.height = '50px';
    imgCircle.src = "/assets/icons/info-sign-disabled.png";
    imgCircle.style.boxShadow = '0 0 8px rgba(0, 0, 0, .8)';
    imgCircle.style.backgroundSize = "60px 60px";
    imgCircle.setAttribute('passedConcept', passedConcept);
    wrapper = document.createElement("div");
    wrapper.id = 'img-wrapper';
    wrapper.className = "disabled";
    wrapper.style.position = 'relative';
    wrapper.style.zIndex = '900';
    wrapper.style.top = '0px';
    wrapper.style.float = 'right';
    wrapper.style.right = '1.5%';
    wrapper.style.cursor = 'pointer';

    wrapper.appendChild(imgCircle);
    wrapper.onclick = function(){
        showLibPopup();
    }

    content.appendChild(wrapper);
}

function hideHelpButton(){
    imgCircle = document.getElementById('img-circle');
    if (imgCircle) imgCircle.parentNode.removeChild(imgCircle);
}

function showLibPopup(){

    if (wrapper && wrapper.className == "disabled"){
        return;
    }

    popupDiv = document.createElement('div');
    popupDiv.className = 'popup-div';
    popupDiv.style.backgroundColor = '#F4F4F4';
    popupDiv.style.border = '1px solid black';
    popupDiv.style.height = (0.64*screen.height) + "px";
    popupDiv.style.padding = '5px';
    popupDiv.style.top = "-7vh";
    popupDiv.style.position = 'absolute';
    popupDiv.style.marginTop = '70px';
    popupDiv.style.width = (0.88*screen.width) + "px";
    popupDiv.style.width = (0.88*screen.width) + "px";
    popupDiv.style.marginLeft = (0.05*screen.width) + "px";
    popupDiv.style.zIndex = '1000';
    content.appendChild(popupDiv);

    popupHeader = document.createElement('div');
    popupHeader.className = 'popup-header';
    popupHeader.innerHTML = 'Data';
    popupHeader.style.borderBottom = '1px solid #7D9EC0';

    popupHeader.style.marginLeft = '-5px';
    popupHeader.style.width = '100%';
    popupHeader.style.backgroundColor = '#F4F4F4';
    popupHeader.style.marginTop = '0px';
    popupHeader.style.paddingTop = '8px';
    popupHeader.style.paddingBottom = '8px';
    popupHeader.style.paddingLeft = '10px';

    popupHeader.style.fontSize = '1.4em';
    popupHeader.style.fontWeight = 'bold';

    popupDiv.appendChild(popupHeader);
    popupData = document.createElement('div');
    popupData.className = 'popup-data';
    popupData.style.height = "81%";
    popupData.style.minWidth = "92.5%";
    popupData.style.overflow = "auto";
    popupData.style.paddingLeft = "20px";
    popupData.style.paddingRight = "20px";
    popupData.style.background = 'white';
    popupData.innerHTML = 'Your data goes here<br /><br /><br />'
    popupDiv.appendChild(popupData);


    popupFooter = document.createElement('div');
    popupFooter.className = 'popup-footer';
    popupFooter.style.position = 'absolute';
    popupFooter.style.width = '98%';
    popupFooter.style.backgroundColor = '#F4F4F4';
    popupFooter.style.bottom = '0px';
    popupFooter.style.paddingTop = '20px';
    popupFooter.style.paddingBottom = '8px';
    popupFooter.style.lineHeight = '1.94857';
    popupFooter.style.height = "6%";
    popupFooter.style.borderTop ='1px solid #7D9EC0';

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
    popupFooter.appendChild(okaySpan);

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

    popupFooter.appendChild(prevSpan);


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
    cancelSpan.style.left = '85%';
    cancelSpan.onclick = function(){
        popupCover = document.getElementsByClassName("popup-cover")[0];
        popupDiv = document.getElementsByClassName("popup-div")[0];
        if (popupCover) popupCover.parentNode.removeChild(popupCover);
        if (popupDiv) popupDiv.parentNode.removeChild(popupDiv);
    }

    popupFooter.appendChild(cancelSpan);
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
    popupCover.style.opacity = '0.4';
    content.appendChild(popupCover);

    loadArticles();
}