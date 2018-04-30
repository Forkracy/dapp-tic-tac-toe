import React, {Component} from 'react';
import styled from 'styled-components';
import Spinner from './Spinner';

const Container = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  width: ${props => props.width}px;
  padding: 1.5rem 2.5rem;
  text-align: center;
  margin-bottom: 5em;
`;

const Table = styled.table`
  width: 100%;
  text-align: center;
`;

const Title = styled.p`
  font-size: 18px;
  font-weight: bold;
`;

const GameName = styled.p`
  font-weight: bold;
  letter-spacing: 1px;
`;

const TxHash = styled.a``;

const Status = styled.div``;

const ConfirmedIcon = styled.svg`
  fill: #00ff31;
  width: 30px;
  height: 30px;
`;

const SpinnerContainer = styled.div`
  display: flex;
  justify-content: center;
`;

const TransactionCointainer = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
`;

class MyTransactions extends Component {
  constructor() {
    super();
    let transactions;
    if (!localStorage.getItem('txs')) {
      transactions = [];
      localStorage.setItem('txs', JSON.stringify(transactions));
    } else {
      transactions = JSON.parse(localStorage.getItem('txs'));
    }

    this.state = {
      transactions: transactions
    };
  }

  componentDidMount() {
    setInterval(() => {
      this.setState({transactions: JSON.parse(localStorage.getItem('txs'))});
      this.fetchData();
      console.log('fetching....');
    }, 2000);
  }

  fetchData() {
    this.state.transactions.forEach(transaction => {
      this.props.web3.eth
        .getTransaction(transaction.tx)
        .then(receipt => {
          if (receipt.blockNumber) {
            transaction.blockNumber = receipt.blockNumber;
            transaction.confirmed = true;
            localStorage.setItem('txs', JSON.stringify(this.state.transactions));
          }
        })
        .catch(reason => {
          console.log(reason);
        });
    });
  }

  render(props) {
    return (
      <TransactionCointainer>
        <h1>Your Transactions</h1>
        <Container
          width={400}
          style={{
            boxShadow: 'rgba(168, 221, 224, 0.5) 0px 0px 15px 3px',
            padding: '1em',
            maxHeight: 330,
            overflow: ' scroll',
            backgroundImage:
              'radial-gradient(farthest-side at 212% 174px,#0177a2 0,#02b8d4 1200px)'
          }}
        >
          <Table>
            <tbody>
              <tr>
                <th>
                  <Title>Name</Title>
                </th>
                <th>
                  <Title>Tx Hash</Title>
                </th>
                <th>
                  <Title>Status</Title>
                </th>
              </tr>
            </tbody>
            <tbody>
              {this.state.transactions.map(transaction => (
                <tr key={transaction.tx}>
                  <td>
                    <GameName>{transaction.gameName}</GameName>
                  </td>
                  <td>
                    <TxHash
                      href={'https://ropsten.etherscan.io/tx/' + transaction.tx}
                      target="_blank"
                    >
                      {transaction.tx.toString().substr(0, 14)}...
                    </TxHash>
                  </td>
                  <td>
                    <Status>
                      {transaction.blockNumber ? (
                        <ConfirmedIcon
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 512 512"
                        >
                          <path d="M504 256c0 136.967-111.033 248-248 248S8 392.967 8 256 119.033 8 256 8s248 111.033 248 248zM227.314 387.314l184-184c6.248-6.248 6.248-16.379 0-22.627l-22.627-22.627c-6.248-6.249-16.379-6.249-22.628 0L216 308.118l-70.059-70.059c-6.248-6.248-16.379-6.248-22.628 0l-22.627 22.627c-6.248 6.248-6.248 16.379 0 22.627l104 104c6.249 6.249 16.379 6.249 22.628.001z" />
                        </ConfirmedIcon>
                      ) : (
                        <SpinnerContainer>
                          <Spinner width={30} height={30} />
                        </SpinnerContainer>
                      )}
                    </Status>
                  </td>
                </tr>
              ))}
            </tbody>
          </Table>
        </Container>
      </TransactionCointainer>
    );
  }
}

export default MyTransactions;
