<template>
  <div class='container mt-4' id="app">
    <b-alert variant="warning" :show='!this.loading && !this.web3'>
      Metamask をインストールするか、DApp ブラウザからアクセスしてください
    </b-alert>
    <b-alert variant="warning" :show='!this.loading && this.web3 && !this.currentAccount'>
      Metamask の場合は、アンロックしてください
    </b-alert>
    <div class="w100 justify-content-between">
      <h2>
        連絡帳
        <span class='float-right'>
          <b-btn
            @click="showNewContact"
            variant='outline-primary'
            size='sm'
            :disabled="!this.currentAccount || loading" >
            連絡先追加
          </b-btn>
        </span>
      </h2>
    </div>
    <b-alert
      variant="success"
      :show='dismissCountDown'
      dismissible
      @dismissed="dismissCountDown=0"
      @dismiss-count-down="countDownChanged"
    >
      {{this.notifity}}
    </b-alert>

    <b-list-group>
      <b-list-group-item v-for="contact in contacts" :key='contact.id' href="#" class="flex-column align-items-start">
        <div class="d-flex w-100 justify-content-between">
          <h5 class="mb-1">{{contact.name}}</h5>
          <div class="float-right">
            <b-btn
              @click="editContact(contact)"
              variant='outline-success'
              size='sm'
              :disabled="!currentAccount">
              編集
            </b-btn>
          </div>
        </div>
        <div>
          {{contact.address}}
          <small class="text-muted">TEL: {{contact.tel}}</small>
        </div>
      </b-list-group-item>
    </b-list-group>
    <b-alert variant="warning" :show='!this.loading && this.contacts.length === 0'>
      まだデータはありません
    </b-alert>
    <b-alert variant="info" :show='this.loading'>
      データ取得中
    </b-alert>
    <b-modal v-model="modalShow" :title="modalTitle" centered>
      <b-form>
        <b-form-group label="名前" label-for="name">
          <b-form-input
            type="text"
            v-model="form.contact.name"
            :state="!$v.form.contact.name.$invalid"
            aria-describedby="nameFeedback"
            :disabled='this.inProgress'
          />
          <b-form-invalid-feedback id="nameFeedback">名前は 2-10 文字で入力してください</b-form-invalid-feedback>
        </b-form-group>
        <b-form-group label="住所" label-for="address">
          <b-form-input
            type="text"
            v-model="form.contact.address"
            :state="!$v.form.contact.address.$invalid"
            aria-describedby="addressFeedback"
            :disabled='this.inProgress'
          />
          <b-form-invalid-feedback id="addressFeedback">住所は 10-20 文字で入力してください</b-form-invalid-feedback>
        </b-form-group>
        <b-form-group label="電話番号" label-for="tel">
          <b-form-input
            type="text"
            v-model="form.contact.tel"
            :state="!$v.form.contact.tel.$invalid"
            aria-describedby="telFeedback"
            :disabled='this.inProgress'
          />
          <b-form-invalid-feedback id="telFeedback">電話番号は 10-13 文字で入力してください</b-form-invalid-feedback>
        </b-form-group>
      </b-form>
      <div class="w100 text-center" v-if='this.pendingTx'>
        <a
          class='btn btn-outline-info'
          :href="this.network.etherscan + '/tx/' + this.pendingTx"
          target="_blank">
          etherscan で確認する
        </a>
      </div>

      <div slot="modal-footer" class="w-100">
        <div class="float-right">
          <b-btn
            @click="deleteContact(form.contact)"
            v-if='isExists'
            size='sm'
            variant='danger'
            :disabled="inProgress" >
            削除する
          </b-btn>
          <b-btn
            @click='saveContact'
            size="sm"
            class="ml-1"
            :variant="modalButtonClass"
            :disabled="inProgress || $v.form.$invalid">
            {{modalButtonText}}
          </b-btn>
        </div>
      </div>
    </b-modal>
  </div>
</template>

<script>
import { validationMixin } from 'vuelidate';
import { required, minLength, maxLength } from 'vuelidate/lib/validators';
import Web3 from 'web3';
import ContractAbi from '../contracts/abi.json';

const CONTRACT_ADDRESS = '0xbcb88d7bca5e3498748182735dcba73459e702e6';

export default {
  name: 'App',
  mixins: [
    validationMixin,
  ],
  data() {
    return {
      loading: false,
      web3: null,
      provider: null,
      currentAccount: null,
      network: null,
      contractInstance: null,
      inProgress: false,
      pendingTx: null,
      notifity: null,
      dismissSecs: 5,
      dismissCountDown: 0,
      modalShow: false,
      form: {
        contact: {
          id: null,
          name: null,
          address: null,
          tel: null,
        },
      },
      contacts: [],
    };
  },
  validations: {
    form: {
      contact: {
        name: { required, minLength: minLength(2), maxLength: maxLength(10) },
        address: { required, minLength: minLength(10), maxLength: maxLength(20) },
        tel: { required, minLength: minLength(10), maxLength: maxLength(13) },
      },
    },
  },
  async created() {
    this.loading = true;

    await this.initWeb3();
    if (this.contractInstance) {
      await this.getContacts();
    }

    this.loading = false;
  },
  computed: {
    isExists() {
      return this.form.contact && this.form.contact.id;
    },
    modalTitle() {
      return this.isExists ? '連絡先編集' : '連絡先新規作成';
    },
    modalButtonClass() {
      return this.isExists ? 'success' : 'primary';
    },
    modalButtonText() {
      return this.isExists ? '更新する' : '登録する';
    },
  },
  methods: {
    async initWeb3() {
      const globalContext = (typeof window === 'object') ? window : global;

      if (globalContext.web3 !== undefined) {
        this.provider = globalContext.web3.currentProvider;
        this.web3 = new Web3(this.provider);
        this.currentAccount = (await this.web3.eth.getAccounts())[0];

        setInterval(async () => {
          const newAccount = (await this.web3.eth.getAccounts())[0];
          if (newAccount !== this.currentAccount) {
            this.currentAccount = newAccount;
          }
        }, 100);

        this.network = await this.initNetwork();
        this.contractInstance = new this.web3.eth.Contract(ContractAbi, CONTRACT_ADDRESS);
      }
    },
    async initNetwork() {
      const chainId = await this.web3.eth.net.getId();
      const data = { chainId };

      switch (chainId) {
        case 1:
          data.chain = 'mainnet';
          data.etherscan = 'https://etherscan.io';
          data.infuraWssUrl = 'wss://mainnet.infura.io/ws';
          break;
        case 2:
          data.chain = 'Morden';
          break;
        case 3:
          data.chain = 'ropsten';
          data.etherscan = 'https://ropsten.etherscan.io/';
          data.infuraWssUrl = 'wss://ropsten.infura.io/ws';
          break;
        case 4:
          data.chain = 'Rinkeby';
          data.etherscan = 'https://rinkeby.etherscan.io/';
          data.infuraWssUrl = 'wss://rinkeby.infura.io/ws';
          break;
        case 42:
          data.chain = 'kovan';
          data.etherscan = 'https://kovan.etherscan.io';
          data.infuraWssUrl = 'wss://kovan.infura.io/ws';
          break;
        case 5777:
          data.chain = 'ganache';
          break;
        default:
          data.chain = 'privatenet';
      }

      return data;
    },
    async getContacts() {
      this.contacts = [];

      const contacts = await this.contractInstance.methods.getContactList().call();

      this.contacts = contacts
        .filter(item => item.id !== '0')
        .map(item => ({ id: item.id, name: item.name, address: item.contactAddress, tel: item.tel }));
    },
    countDownChanged(dismissCountDown) {
      this.dismissCountDown = dismissCountDown;
    },
    showAlert() {
      this.dismissCountDown = this.dismissSecs;
    },
    showNewContact() {
      this.form.contact = {
        id: null,
        name: null,
        address: null,
        tel: null,
      };

      this.modalShow = true;
    },
    editContact(contact) {
      Object.assign(this.form.contact, contact);

      this.modalShow = true;
    },
    deleteContact(contact) {
      if (confirm('連絡先を削除します。よろしいですか？')) {
        this.inProgress = true;
        this.pendingTx = null;

        try {
          this.contractInstance.methods.deleteContact(
            contact.id,
          ).send({
            from: this.currentAccount,
          }).on('transactionHash', (hash) => {
            this.pendingTx = hash;
          }).once('confirmation', async () => {
            this.pendingTx = null;
            this.inProgress = false;

            await this.getContacts();

            this.modalShow = false;
            this.notifity = '連絡先を削除しました';
            this.dismissCountDown = this.dismissSecs;
          })
            .on('error', async (err) => {
              console.error(err);
              this.inProgress = false;
            });
        } catch (e) {
          console.error(e);
          this.inProgress = false;
        }
      }
    },
    saveContact() {
      this.inProgress = true;
      this.pendingTx = null;

      try {
        if (this.form.contact.id) {
          const index = this.contacts.findIndex(item => item.id === this.form.contact.id);
          const contact = this.contacts[index];
          Object.assign(contact, this.form.contact);

          this.contractInstance.methods.updateContact(
            contact.id, contact.name, contact.address, contact.tel,
          ).send({
            from: this.currentAccount,
          }).on('transactionHash', (hash) => {
            this.pendingTx = hash;
          }).once('confirmation', async () => {
            this.pendingTx = null;
            this.inProgress = false;

            await this.getContacts();

            this.modalShow = false;
            this.notifity = '連絡先を更新しました';
            this.dismissCountDown = this.dismissSecs;
          })
            .on('error', async (err) => {
              console.error(err);
              this.inProgress = false;
            });
        } else {
          const contact = Object.assign({}, this.form.contact);

          this.contractInstance.methods.addContact(
            contact.name, contact.address, contact.tel,
          ).send({
            from: this.currentAccount,
          }).on('transactionHash', (hash) => {
            this.pendingTx = hash;
          }).once('confirmation', async () => {
            this.pendingTx = null;
            this.inProgress = false;

            await this.getContacts();

            this.modalShow = false;
            this.notifity = '連絡先を新規作成しました';
            this.dismissCountDown = this.dismissSecs;
          })
            .on('error', async (err) => {
              console.error(err);
              this.inProgress = false;
            });
        }
      } catch (e) {
        console.error(e);
        this.inProgress = false;
      }
    },
  },
};
</script>

<style>

</style>
