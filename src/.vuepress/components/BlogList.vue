<template>
  <div>
      <div class="posts">
        <div v-for="post in posts" class="post">
          <a :href="post.path">{{ post.title }}</a>
        </div>
      </div>
    </ul>
  </div>
</template>

<script>
export default {
	props: {
		limit : Number
	},
	computed:{
		posts() {
			let posts = this.$site.pages.filter(p => {
				 return p.frontmatter.type == 'blogpost'
			}).sort((a,b) => {
				let aDate = new Date(a.frontmatter.datecreated).getTime();
        		let bDate = new Date(b.frontmatter.datecreated).getTime();
				let diff = bDate - aDate;
				if(diff < 0) return -1;
				if(diff > 0) return 1;
				return 0;
			});
			if(this.$props.limit){
				posts = posts.slice(0,this.$props.limit);
			}
			return posts;
		}
	}
}
</script>

<style>
.posts {
  margin: 10px 0px;
}
.post {
    margin-bottom: 15px;
}
</style>
