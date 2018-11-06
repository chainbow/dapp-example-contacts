<template>
  <div class='container mt-4' id="app">
    <div class="w100 justify-content-between">
      <h2>
        連絡帳
        <span class='float-right'>
          <b-btn @click="showNewContact" variant='primary' size='sm'>連絡先追加</b-btn>
        </span>
      </h2>
    </div>

    <b-list-group>
      <b-list-group-item v-for="contact in contacts" :key='contact.id' href="#" class="flex-column align-items-start">
        <div class="d-flex w-100 justify-content-between">
          <h5 class="mb-1">{{contact.name}}</h5>
          <div class="float-right">
            <b-btn @click="editContact(contact)" variant='outline-success' size='sm'>編集</b-btn>
            <b-btn @click="deleteContact(contact)" variant='outline-danger' size='sm' class='ml-2'>削除</b-btn>
          </div>
        </div>
        <div>
          {{contact.address}}
          <small class="text-muted">TEL: {{contact.tel}}</small>
        </div>
      </b-list-group-item>
    </b-list-group>
    <b-modal v-model="modalShow" :title="modalTitle" centered>
      <b-form>
        <b-form-group label="名前" label-for="name">
          <b-form-input
            type="text"
            v-model="form.contact.name"
            :state="!$v.form.contact.name.$invalid"
            aria-describedby="nameFeedback"
          />
          <b-form-invalid-feedback id="nameFeedback">名前は 2-10 文字で入力してください</b-form-invalid-feedback>
        </b-form-group>
        <b-form-group label="住所" label-for="address">
          <b-form-input
            type="text"
            v-model="form.contact.address"
            :state="!$v.form.contact.address.$invalid"
            aria-describedby="addressFeedback"
          />
          <b-form-invalid-feedback id="addressFeedback">住所は 10-20 文字で入力してください</b-form-invalid-feedback>
        </b-form-group>
        <b-form-group label="電話番号" label-for="tel">
          <b-form-input
            type="text"
            v-model="form.contact.tel"
            :state="!$v.form.contact.tel.$invalid"
            aria-describedby="telFeedback"
          />
          <b-form-invalid-feedback id="telFeedback">電話番号は 10-13 文字で入力してください</b-form-invalid-feedback>
        </b-form-group>
      </b-form>

      <div slot="modal-footer" class="w-100">
        <div class="float-right">
          <b-btn size="sm" variant="default" @click="modalShow = false">
            キャンセル
          </b-btn>
          <b-btn size="sm" class="ml-1" :variant="modalButtonClass" @click="saveContact" :disabled="$v.form.$invalid">
            {{modalButtonText}}
          </b-btn>
        </div>
      </div>
    </b-modal>
  </div>
</template>

<script>
import Vue from 'vue';
import { validationMixin } from 'vuelidate';
import { required, minLength, maxLength } from 'vuelidate/lib/validators';

export default {
  name: 'App',
  mixins: [
    validationMixin,
  ],
  data() {
    return {
      modalShow: false,
      modalTitle: '',
      modalButtonText: '追加する',
      modalButtonClass: 'primary',
      form: {
        contact: {
          id: null,
          name: null,
          address: null,
          tel: null,
        },
      },
      contacts: [
        { id: 1, name: '山田太郎', address: '東京都渋谷区', tel: '08011112222' },
        { id: 2, name: '田中太郎', address: '東京都文京区', tel: '08033334444' },
        { id: 3, name: '山下太郎', address: '横浜市西区', tel: '09055556666' },
      ],
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
  methods: {
    showNewContact() {
      this.modalTitle = '連絡先追加';
      this.modalButtonText = '追加する';
      this.modalButtonClass = 'primary';

      this.form.contact = {
        id: null,
        name: null,
        address: null,
        tel: null,
      };

      this.modalShow = true;
    },
    editContact(contact) {
      this.modalTitle = '連絡先編集';
      this.modalButtonText = '更新する';
      this.modalButtonClass = 'success';
      Object.assign(this.form.contact, contact);

      this.modalShow = true;
    },
    deleteContact(contact) {
      if (confirm('連絡先を削除します。よろしいですか？')) {
        this.contancts = this.contancts.filter(item => item.id !== contact.id);
      }
    },
    saveContact() {
      if (this.form.contact.id) {
        const index = this.contancts.findIndex(item => item.id === this.form.contact.id);
        const contact = this.contancts[index];
        Object.assign(contact, this.form.contact);

        Vue.set(this.contancts, index, contact);
      } else {
        const contact = {};
        Object.assign(contact, this.form.contact);

        this.contancts.push(contact);
      }

      this.modalShow = false;
    },
  },
};
</script>

<style>

</style>
