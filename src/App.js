import React, {Component, createContext} from 'react';
import styled from 'styled-components';
import Login from './Game/login';
import './App.css';
import Context from './Game/Context';
import Web3 from 'web3';
let web3 = window.web3;

const Container = styled.div`
  display: flex;
  flex-direction: column;
`;

class App extends Component {
  constructor() {
    super();
    this.state = {ethAddress: '', ethBalance: 0};
  }

  componentDidMount() {
    this.initWeb3();
  }

  getUserAccount() {
    web3.eth
      .getAccounts()
      .then(addr => {
        this.setState({ethAddress: addr.toString()});
        web3.eth
          .getBalance(addr.toString())
          .then(bal => {
            var inEth = web3.utils.fromWei(bal, "ether");
            this.setState({ethBalance: inEth});
          })
          .catch(err => {
            console.log('error getting balance' + err);
          });
      })
      .catch(err => {
        console.log('error getting address ' + err);
      });
  }

  initWeb3() {
    if (typeof web3 !== 'undefined') {
      this.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
      console.log('existing web3: provider ' + web3.currentProvider);
    } else {
      this.web3Provider = new Web3.providers.HttpProvider(
        'http://localhost:8545'
      );
      web3 = new Web3(this.web3Provider);
      console.log('new web3');
    }
    this.getUserAccount();
  }

  render() {
    return (
      <Context.Provider value={this.state}>
        <Container>
          <Login />
        </Container>
      </Context.Provider>
    );
  }
}

export default App;
