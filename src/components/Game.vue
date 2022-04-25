<template>
  <v-container>
    <v-row class="text-center">
      <v-dialog v-model="finished" persistent>
        <v-card v-if="finished">
           <v-card-title><span class="headline">{{ texts.storyOf + meName }}:</span></v-card-title>
           <v-card-text>
             <v-container>
               <v-row v-for="(quest, index) in quests" :key="quest">
                 <v-col cols="12" sm="6" md="4">
                   <strong>{{ quest }}</strong>
                 </v-col>
                 <v-col cols="12" sm="6" md="4">
                   {{ shared.sheets[meI][index] }}
                 </v-col>
               </v-row>
             </v-container>
           </v-card-text>
           <v-card-actions>
           <v-spacer></v-spacer>
           <v-btn color="blue darken-1" text @click="restart" v-if="isHost">Do another one!</v-btn>
           </v-card-actions>
        </v-card>
      </v-dialog>
      <v-dialog v-model="dialog" persistent>
        <v-card>
           <v-card-title>
             <span class="headline">
               {{ texts.namePrompt }}
             </span>
           </v-card-title>
           <v-card-text>
             <v-container>
               <v-row>
               <v-col cols="12" sm="6" md="4">
                 <v-text-field v-model="meNameInput" label="Name" hint="You remember who you are? Good!" >
                 </v-text-field>
               </v-col>
               <v-col cols="12" sm="6" md="4">
                 <v-combobox v-model="meAvatar" :items="avatars">
                   <template v-slot:item="{ item }">
                     <i :class="['fa', 'fa-2x', item]"></i>
                   </template>
                 </v-combobox>
               </v-col>
               </v-row>
             </v-container>
           </v-card-text>
           <v-card-actions>
           <v-spacer></v-spacer>
           <v-btn color="blue darken-1" text @click="login">
             {{ texts.confirmBtn}}
           </v-btn>
           </v-card-actions>
        </v-card>
      </v-dialog>
      <v-row>
      <v-col class="mb-4">
        <v-timeline align-top dense>
          <v-timeline-item :color="(shared.sheets[(index+shared.round+shared.modulo) % shared.players.length][shared.round].length !== 0) ? 'green' : 'blue'" align-top dense v-for="(player, index) in shared.players" :key="index">
            <template v-slot:icon>
               <i :class="['fa', (shared.sheets[(index+shared.round+shared.modulo) % shared.players.length][shared.round].length !== 0) ? 'fa-check' : 'fa-ellipsis-h']"></i>
            </template>
            <v-card :color="['blue', (meI === index) ? 'darken-1' : 'lighten-2'].join(' ')">
              <v-card-title class="title">
                <i :class="['fa', 'fa-fw', 'fa-3x', player.avatar]"></i>
                <v-spacer />
                {{ player.name }}
                <v-spacer />
                <v-btn v-if="isHost && meI !== index" @click="kick(index)" class="mx-2" fab small color="red">
                    <v-icon dark>mdi-minus</v-icon>
                </v-btn>
              </v-card-title>
            </v-card>
          </v-timeline-item>
        </v-timeline>
      </v-col>
      <v-col class="mb-4" v-if="shared.players && shared.players.length !== 0">
        {{ quests[shared.round] }}
        <v-textarea @keydown.enter.prevent="submit" :clearable="true" :auto-grow="true" :disabled="answerDone" v-model="answerInput"></v-textarea>
        <v-btn :disabled="answerDone" @click="submit" class="mx-2" fab small color="blue">
          <v-icon dark>mdi-send</v-icon>
        </v-btn>
      </v-col>
      </v-row>
    </v-row>
  </v-container>
</template>

<script>
import jsonpatch from 'json-patch';

const i18n = {
  "de": {
    "quests": [
      "Wo warst du gestern?",
      "Was hast du da gemacht?",
      "Wen hast du da getroffen?",
      "Was hast du gesagt?",
      "Was hat derjenige dann geantwortet?",
      "Was ist dann passiert?",
    ],
    "namePrompt": "Was ist dein Name? Und was repräsentiert dich am Besten?",
    "confirmBtn": "Das bin ich!",
    "storyOf": "Das ist die Geschichte einer Person mit dem Namen "
  },
  "en": {
    "quests": [
      "Where have you been yesterday?",
      "What did you do there?",
      "Who did you meet?",
      "What did you say?",
      "What did they answer?",
      "What happened then?",
    ],
    "namePrompt": "What is your name? And what icon represents you best?",
    "confirmBtn": "Thats exactly me!",
    "storyOf": "This is a story of a person called "
  }
}
  export default {
    name: 'FoldgameGame',
    created: function() {
      this.connectToWs();
      setInterval(this.pushUpdateIfHost, 1000);
    },
    methods: {
      kick: function(index) {
        this.shared.players.splice(index, 1)
        this.shared.sheets.splice(index, 1)
        this.shared.sheets.push(['', '', '', '', '', '', ''])
        this.conn.send(JSON.stringify(this.shared))
      },
      connectToWs: function() {
        let self = this;
        let conn = new WebSocket("wss://" + document.location.host + "/ws");
        conn.onclose = function () {
          setTimeout(self.connectToWs, 1000);
        };
        conn.onmessage = this.handleUpdate;
        conn.onopen = function () {
        }
        this.conn = conn;
      },
      pushUpdateIfHost: function() {
        if(this.isHost && this.conn) {
          this.conn.send(JSON.stringify(this.shared));
        }
      },
      handleSingleUpdate : function(message) {
        let self = this;
        if (this.isHost) {
          if (message.cntreq === true) { // Someone asked for init data
            self.conn.send(JSON.stringify(self.shared));
          }
          if (message.patch !== undefined) { // It's a patch!
            jsonpatch.apply(self.shared, message.patch);
            self.conn.send(JSON.stringify(self.shared))
          }
          // Check if we can do round++
          if (this.shared.players.length > 0) {
            for (let i=0;i<this.shared.players.length;i++){
              if (this.shared.sheets[i][this.shared.round].length === 0) {
                return;
              }
            }
            if (this.shared.round < this.quests.length) {
              this.shared.round++;
              self.answerInput = "";
              self.conn.send(JSON.stringify(self.shared));
            }
          }
        } else {
          if (message.players !== undefined) {
            if (self.shared.round !== message.round && self.answerDone) {
               self.answerInput = "";
            }
            self.shared = message;
          }
        }
      },
      handleUpdate: function(evt) {
        var messages = evt.data.split('\n');
        let self = this;
        for (var i = 0; i < messages.length; i++) {
           let message = JSON.parse(messages[i]);
           self.handleSingleUpdate(message);
        }
      },
      login: function() {
        if (this.meNameInput.length === 0) {
           return;
        }
        this.meName = this.meNameInput
        // Seems like we are the host
        if (!this.shared.players || this.shared.players.length === 0) {
            this.shared.players.push({
            name: this.meName,
            avatar: this.meAvatar
          });
          this.conn.send(JSON.stringify(this.shared));
        } else { // Seems like we are a normal player
          this.conn.send(JSON.stringify({patch: {
            op: "add",
            path: "/players/-",
            value: {
              name: this.meName,
              avatar: this.meAvatar
            }
          }}));
        }
      },
      submit: function() {
        if (this.answerInput.length === 0 || this.answerInput === "\n") {
            return;
        }
        this.conn.send(JSON.stringify({patch: {
          op: "replace",
          path: "/sheets/"+this.myCurrentSheetI+"/"+this.shared.round,
          value: this.answerInput
        }}));
      },
      restart: function() {
         this.shared.modulo = Math.floor(Math.random()*100);
         this.shared.round = 0;
         this.shared.sheets = [
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
           ['', '', '', '', '', '', ''],
         ];
         this.conn.send(JSON.stringify(this.shared));
      }
    },
    computed: {
      meI: function() {
        if(!this.shared.players){
            return -1;
        }
        for (let i=0; i<this.shared.players.length;i++) {
          if (this.shared.players[i].name == this.meName) {
            return i;
          }
        }
        return -1;
      },
      finished: function() {
         return this.shared.round == this.quests.length
      },
      isHost: function() {
         return this.meI === 0 && this.shared.players && this.shared.players.length > 0;
      },
      dialog: function() {
         return this.meI === -1;
      },
      myCurrentSheetI: function () {
         return (this.meI+this.shared.round+this.shared.modulo) % this.shared.players.length;
      },
      answerDone: function() {
         if (this.meI === -1) {
            return false;
         }
         return this.shared.sheets[this.myCurrentSheetI][this.shared.round].length !== 0
      }
    },
    data: () => ({
      conn: null,
      quests: i18n[navigator.language] ? i18n[navigator.language].quests : i18n["en"].quests,
      texts: {
        "namePrompt": i18n[navigator.language] ? i18n[navigator.language].namePrompt : i18n["en"].namePrompt,
        "confirmBtn": i18n[navigator.language] ? i18n[navigator.language].confirmBtn : i18n["en"].confirmBtn,
        "storyOf": i18n[navigator.language] ? i18n[navigator.language].storyOf : i18n["en"].storyOf,
      },
      meName: "",
      meNameInput: "",
      meAvatar: "",
      answerInput: "",
      shared: {
          round: 0,
          modulo: Math.floor(Math.random()*100),
          players: [],
          sheets: [
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
            ['', '', '', '', '', '', ''],
          ]
      },
      avatars: [
        'fa-running',
        'fa-baby',
        'fa-user-tie',
        'fa-robot',
        'fa-tree',
        'fa-skiing',
        'fa-snowman',
        'fa-cat',
        'fa-kiwi-bird',
        'fa-user-graduate',
        'fa-user-md',
        'fa-user-injured',
        'fa-user-astronaut',
        'fa-user-ninja',
        'fa-user-secret',
        'fa-poo',
        'fa-viruses',
        'fa-hippo',
        'fa-otter',
        'fa-dog',
        'fa-dove',
        'fa-fire-alt',
        'fa-crown',
        // animals
        'fa-crow',
        'fa-fish',
        'fa-frog',
        'fa-spider',
        // Podcast
        'fa-podcast',
        // Autos
        'fa-truck',
        'fa-truck-monster',
        'fa-shuttle-van',
        'fa-caravan',
        // Emojis
        'fa-meh-rolling-eyes',
        'fa-meh-blank',
        'fa-smile',
        'fa-laugh',
        'fa-kiss-wink-heart',
        'fa-tired',
        'fa-dizzy',
        'fa-angry'
      ]
   })
  }
</script>
