<template>
  <v-app>
    <v-app-bar
      app
      color="primary"
      dark
    >
      <i class="fa fa-map fa-2x fa-rotate-90"></i>
      <v-spacer></v-spacer>
      <span style="font-size: 2em">Foldgame</span>
      <v-spacer></v-spacer>
      <i class="fa fa-map fa-2x fa-rotate-90"></i>
    </v-app-bar>

    <v-main>
      <Game/>
    </v-main>
  </v-app>
</template>

<script>
import Game from './components/Game';
window.onbeforeunload = function() {
  return "Do not leave, you may have unfinished business";
}


export default {
  name: 'App',

  components: {
    Game,
  },

  data: () => ({
    //
  }),
};
</script>
