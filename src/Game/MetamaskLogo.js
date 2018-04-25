import React, {Component} from 'react';
import styled from 'styled-components'

let ModelViewer = require('metamask-logo');

const Container = styled.div`

`;

// To render with fixed dimensions:
let viewer = ModelViewer({

    // Dictates whether width & height are px or multiplied
    pxNotRatio: true,
    width: 200,
    height: 200,
    // pxNotRatio: false,
    // width: 0.9,
    // height: 0.9,

    // To make the face follow the mouse.
    followMouse: false,

    // head should slowly drift (overrides lookAt)
    slowDrift: false,

});

// add viewer to DOM
let container = document.getElementById('logo-container');
// container.appendChild(viewer.container);

// look at something on the page
viewer.lookAt({
    x: 100,
    y: 100,
});

// enable mouse follow
viewer.setFollowMouse(true);

// deallocate nicely
viewer.stopAnimation();

class MetaMaskLogo extends  Component{
    componentDidMount() {
        this.container.appendChild(viewer.container);
    }
    shouldComponentUpdate() {
        return false;
    }
    render() {
        return (<Container innerRef={ref => {
            this.container = ref;
        }}/>);

    }
};

export default MetaMaskLogo;