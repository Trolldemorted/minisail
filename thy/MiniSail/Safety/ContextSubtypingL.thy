(*<*)
theory ContextSubtypingL
  imports TypingL "HOL-Eisbach.Eisbach_Tools" Explorer 
begin
(*>*)

declare freshers[simp del]

chapter \<open>Context Subtyping  Lemmas\<close>


text \<open>Lemmas allowing us to replace the type of a variable in the context with a subtype
and have the judgement remain valid. Sometimes known as narrowing.\<close>

section \<open>Replace Type of Variable in Context\<close>

text \<open> Because the G-context is extended by the statements like let, we will need a generalised 
substitution lemma for statements. 
For this we setup a function that replaces in G for a particular x the constraint for it\<close>

nominal_function replace_in_g_many :: "\<Gamma> \<Rightarrow> (x*c) list \<Rightarrow> \<Gamma>" where
  "replace_in_g_many G xcs = List.foldr (\<lambda>(x,c) G. G[x \<longmapsto> c]) xcs G"
by(auto,simp add: eqvt_def replace_in_g_many_graph_aux_def)
nominal_termination (eqvt)  by lexicographic_order

inductive replace_in_g_subtyped :: "\<Theta> \<Rightarrow> \<B> \<Rightarrow> \<Gamma> \<Rightarrow> (x*c) list \<Rightarrow> \<Gamma> \<Rightarrow> bool" (" _ ; _  \<turnstile> _ \<langle> _ \<rangle> \<leadsto> _" [100,50,50] 50) where
  replace_in_g_subtyped_nilI: "\<Theta> ; \<B> \<turnstile> G \<langle> [] \<rangle> \<leadsto> G"
| replace_in_g_subtyped_consI:  "\<lbrakk> 
       Some (b,c') = lookup G x ; 
        \<Theta> ; \<B> ; G \<turnstile>\<^sub>w\<^sub>f c ;
       \<Theta> ; \<B> ; G[x\<longmapsto>c] \<Turnstile> c' ; 
       \<Theta> ; \<B> \<turnstile> G[x\<longmapsto>c] \<langle> xcs \<rangle> \<leadsto> G'; x \<notin> fst ` set xcs \<rbrakk>  \<Longrightarrow> 
       \<Theta> ; \<B> \<turnstile> G \<langle> (x,c)#xcs \<rangle> \<leadsto> G'" 
equivariance replace_in_g_subtyped
nominal_inductive replace_in_g_subtyped .

inductive_cases replace_in_g_subtyped_elims[elim!]:
  "\<Theta> ; \<B> \<turnstile> G \<langle> [] \<rangle> \<leadsto> G'"
  "\<Theta> ; \<B> \<turnstile> ((x,b,c)#\<^sub>\<Gamma>\<Gamma> G) \<langle> acs \<rangle> \<leadsto> ((x,b,c)#\<^sub>\<Gamma>G')"
  "\<Theta> ; \<B> \<turnstile> G' \<langle> (x,c)# acs \<rangle> \<leadsto> G"


lemma rigs_atom_dom_eq:
  assumes "\<Theta> ; \<B> \<turnstile> G \<langle> xcs \<rangle> \<leadsto> G'"
  shows "atom_dom G = atom_dom G'"
using assms proof(induct rule: replace_in_g_subtyped.induct)
  case (replace_in_g_subtyped_nilI G)
  then show ?case by simp
next
  case (replace_in_g_subtyped_consI b c' G x \<Theta> \<B> c xcs G')
  then show ?case using rig_dom_eq atom_dom.simps dom.simps by simp
qed

lemma replace_in_g_wfG:
  assumes "\<Theta> ; \<B> \<turnstile> G \<langle> xcs \<rangle> \<leadsto> G'" and  "wfG \<Theta> \<B> G "
  shows "wfG \<Theta> \<B> G'"
  using assms proof(induct rule: replace_in_g_subtyped.induct)
  case (replace_in_g_subtyped_nilI \<Theta> G)
  then show ?case by auto
next
  case (replace_in_g_subtyped_consI b c' G x \<Theta> c xcs G')
  then show ?case using valid_g_wf by auto
qed




lemma wfD_rig_single:
  fixes \<Delta>::\<Delta> and x::x and c::c and G::\<Gamma>
  assumes "\<Theta> ; \<B> ; G \<turnstile>\<^sub>w\<^sub>f \<Delta> " and  "wfG \<Theta> \<B> (G[x\<longmapsto>c])"
  shows "\<Theta> ; \<B> ; G[x\<longmapsto>c]  \<turnstile>\<^sub>w\<^sub>f \<Delta>" 
proof(cases "atom x \<in> atom_dom G")
  case False
  hence "(G[x\<longmapsto>c]) = G" using assms replace_in_g_forget wfX_wfY by metis
  then show ?thesis using assms by auto
next
  case True
  then obtain G1 G2 b c' where *: "G=G1@(x,b,c')#\<^sub>\<Gamma>G2" using split_G by fastforce
  hence **: "(G[x\<longmapsto>c]) = G1@(x,b,c)#\<^sub>\<Gamma>G2" using replace_in_g_inside wfD_wf  assms wfD_wf by metis

  hence "wfG \<Theta> \<B> ((x,b,c)#\<^sub>\<Gamma>G2)" using wfG_suffix assms by auto
  hence "\<Theta> ; \<B> ; (x, b, TRUE) #\<^sub>\<Gamma> G2  \<turnstile>\<^sub>w\<^sub>f c" using wfG_elim2 by auto

  thus ?thesis using wf_replace_inside1 assms * ** 
    by (simp add: wf_replace_inside2(6))
qed



lemma wfD_rig:
  assumes  "\<Theta> ; \<B> \<turnstile> G \<langle> xcs \<rangle> \<leadsto> G'" and "wfD \<Theta> \<B> G \<Delta>" 
  shows "wfD \<Theta> \<B> G' \<Delta>" 
using assms proof(induct rule: replace_in_g_subtyped.induct)
  case (replace_in_g_subtyped_nilI \<Theta> G)
  then show ?case by auto
next
  case (replace_in_g_subtyped_consI b c' G x \<Theta> c xcs G')
  then show ?case using wfD_rig_single valid.simps wfC_wf by auto
qed

lemma replace_in_g_fresh:
  fixes x::x
  assumes "\<Theta> ; \<B> \<turnstile> \<Gamma> \<langle> xcs \<rangle> \<leadsto> \<Gamma>'" and  "wfG \<Theta> \<B> \<Gamma>" and "wfG \<Theta> \<B> \<Gamma>'" and "atom x \<sharp> \<Gamma>"
  shows "atom x \<sharp> \<Gamma>'"
using  wfG_dom_supp assms fresh_def rigs_atom_dom_eq by metis

lemma replace_in_g_fresh1:
  fixes x::x
  assumes "\<Theta> ; \<B> \<turnstile> \<Gamma> \<langle> xcs \<rangle> \<leadsto> \<Gamma>'" and  "wfG \<Theta> \<B> \<Gamma>" and "atom x \<sharp> \<Gamma>"
  shows "atom x \<sharp> \<Gamma>'"
proof -
  have  "wfG \<Theta> \<B> \<Gamma>'" using  replace_in_g_wfG assms by auto
  thus ?thesis using assms replace_in_g_fresh by metis
qed

text \<open> Wellscoping for an eXchange list\<close>
inductive wsX:: "\<Gamma> \<Rightarrow> (x*c) list \<Rightarrow> bool" where
  wsX_NilI: "wsX G []"
 |  wsX_ConsI: "\<lbrakk> wsX G xcs ; atom x \<in> atom_dom G ; x \<notin> fst ` set xcs \<rbrakk> \<Longrightarrow> wsX G ((x,c)#xcs)"
equivariance wsX
nominal_inductive wsX .

lemma wsX_if1:
  assumes "wsX G xcs"
  shows "(( atom ` fst ` set xcs) \<subseteq> atom_dom G) \<and> List.distinct (List.map fst xcs)"
using assms by(induct rule: wsX.induct,force+ )

lemma wsX_if2:
  assumes  "(( atom ` fst ` set xcs) \<subseteq> atom_dom G) \<and> List.distinct (List.map fst xcs)"
  shows  "wsX G xcs"
using assms proof(induct xcs)
  case Nil
  then show ?case using wsX_NilI by fast
next
  case (Cons a xcs)
  then obtain x and c where xc: "a=(x,c)" by force
  have " wsX G xcs" proof -
    have "distinct (map fst xcs)" using Cons by force
    moreover have " atom ` fst ` set xcs \<subseteq> atom_dom G" using Cons by simp
    ultimately show ?thesis  using Cons by fast
  qed
  moreover have "atom x \<in> atom_dom G" using Cons xc 
    by simp
  moreover have "x \<notin> fst ` set xcs" using Cons xc 
    by simp
  ultimately show ?case using wsX_ConsI xc by blast
qed

lemma wsX_iff:
  "wsX G xcs = ((( atom ` fst ` set xcs) \<subseteq> atom_dom G) \<and> List.distinct (List.map fst xcs))"
  using wsX_if1 wsX_if2 by meson

inductive_cases wsX_elims[elim!]:
  "wsX G []"
  "wsX G ((x,c)#xcs)"

lemma wsX_cons:
  assumes  "wsX \<Gamma> xcs" and  "x \<notin> fst ` set xcs" 
  shows "wsX ((x, b, c1) #\<^sub>\<Gamma> \<Gamma>) ((x, c2) # xcs)" 
using assms proof(induct \<Gamma>)
  case GNil
  then show ?case using atom_dom.simps wsX_iff by auto
next
  case (GCons xbc \<Gamma>)
  obtain x' and b' and c' where xbc: "xbc = (x',b',c')" using prod_cases3 by blast
  then have "atom ` fst ` set xcs \<subseteq> atom_dom (xbc #\<^sub>\<Gamma> \<Gamma>) \<and> distinct (map fst xcs)"
    using GCons.prems(1) wsX_iff by blast
  then have "wsX ((x, b, c1) #\<^sub>\<Gamma> xbc #\<^sub>\<Gamma> \<Gamma>) xcs"
   by (simp add: Un_commute subset_Un_eq wsX_if2) 
  then show ?case   by (simp add: GCons.prems(2) wsX_ConsI) 
qed

lemma wsX_cons2:
  assumes  "wsX \<Gamma> xcs" and  "x \<notin> fst ` set xcs" 
  shows "wsX ((x, b, c1) #\<^sub>\<Gamma> \<Gamma>)  xcs" 
using assms proof(induct \<Gamma>)
  case GNil
  then show ?case using atom_dom.simps wsX_iff by auto
next
  case (GCons xbc \<Gamma>)
  obtain x' and b' and c' where xbc: "xbc = (x',b',c')" using prod_cases3 by blast
  then have "atom ` fst ` set xcs \<subseteq> atom_dom (xbc #\<^sub>\<Gamma> \<Gamma>) \<and> distinct (map fst xcs)"
    using GCons.prems(1) wsX_iff by blast then show ?case by (simp add: Un_commute subset_Un_eq wsX_if2) 
qed

lemma wsX_cons3:
  assumes  "wsX \<Gamma> xcs"  
  shows "wsX ((x, b, c1) #\<^sub>\<Gamma> \<Gamma>)  xcs" 
using assms proof(induct \<Gamma>)
  case GNil
  then show ?case using atom_dom.simps wsX_iff by auto
next
  case (GCons xbc \<Gamma>)
  obtain x' and b' and c' where xbc: "xbc = (x',b',c')" using prod_cases3 by blast
  then have "atom ` fst ` set xcs \<subseteq> atom_dom (xbc #\<^sub>\<Gamma> \<Gamma>) \<and> distinct (map fst xcs)"
    using GCons.prems(1) wsX_iff by blast then show ?case by (simp add: Un_commute subset_Un_eq wsX_if2) 
qed

lemma wsX_fresh:
  assumes "wsX G xcs" and "atom x \<sharp> G" and "wfG \<Theta> \<B> G "
  shows "x \<notin> fst ` set xcs"
proof - 
  have "atom x \<notin> atom_dom G" using assms 
    using fresh_def wfG_dom_supp by auto
  thus ?thesis using wsX_iff assms by blast
qed

lemma replace_in_g_dist:
  assumes "x' \<noteq> x" 
  shows "replace_in_g ((x, b,c) #\<^sub>\<Gamma> G) x' c'' = ((x, b,c) #\<^sub>\<Gamma> (replace_in_g G x' c''))" using replace_in_g.simps assms by presburger

lemma wfG_replace_inside_rig:
  fixes c''::c
  assumes \<open>\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f G[x'\<longmapsto>c'']\<close> \<open>\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f (x, b, c) #\<^sub>\<Gamma> G \<close>
  shows "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f (x, b, c) #\<^sub>\<Gamma> G[x'\<longmapsto>c'']"
proof(rule wfG_consI)

  have "wfG \<Theta> \<B> G " using wfG_cons assms by auto

  show *:"\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f G[x'\<longmapsto>c'']" using assms by auto
  show "atom x \<sharp> G[x'\<longmapsto>c'']" using replace_in_g_fresh_single[OF *] assms wfG_elims assms by metis
  show **:"\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f b " using wfG_elim2 assms by auto
  show "\<Theta> ; \<B> ; (x, b, TRUE) #\<^sub>\<Gamma> G[x'\<longmapsto>c'']  \<turnstile>\<^sub>w\<^sub>f c "
  proof(cases "atom x' \<notin> atom_dom G")
    case True
    hence "G = G[x'\<longmapsto>c'']" using replace_in_g_forget \<open>wfG \<Theta> \<B> G\<close>  by auto
    thus ?thesis using assms wfG_wfC by auto
  next
    case False
    then obtain G1 G2 b' c' where **:"G=G1@(x',b',c')#\<^sub>\<Gamma>G2"
      using split_G by fastforce
    hence ***: "(G[x'\<longmapsto>c'']) = G1@(x',b',c'')#\<^sub>\<Gamma>G2"
      using replace_in_g_inside \<open>wfG \<Theta> \<B> G \<close>  by metis
    hence "\<Theta> ; \<B> ; (x, b, TRUE) #\<^sub>\<Gamma> G1@(x',b',c')#\<^sub>\<Gamma>G2  \<turnstile>\<^sub>w\<^sub>f c" using * ** assms wfG_wfC by auto
    hence  "\<Theta> ; \<B> ; (x, b, TRUE) #\<^sub>\<Gamma> G1@(x',b',c'')#\<^sub>\<Gamma>G2  \<turnstile>\<^sub>w\<^sub>f c" using * *** wf_replace_inside assms
      by (metis "**" append_g.simps(2) wfG_elim2 wfG_suffix)
    thus ?thesis using ** * *** by auto
  qed
qed

lemma replace_in_g_valid_weakening:
  assumes "\<Theta> ; \<B> ; \<Gamma>[x'\<longmapsto>c''] \<Turnstile> c'" and "x' \<noteq> x" and  "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f (x, b, c) #\<^sub>\<Gamma> \<Gamma>[x'\<longmapsto>c'']"
  shows "\<Theta> ; \<B> ; ((x, b,c) #\<^sub>\<Gamma> \<Gamma>)[x'\<longmapsto> c'']  \<Turnstile> c'"
  apply(subst replace_in_g_dist,simp add: assms,rule valid_weakening)
  using assms by auto+

lemma replace_in_g_subtyped_cons:
  assumes "replace_in_g_subtyped \<Theta> \<B> G xcs G'"  and "wfG \<Theta> \<B> ((x,b,c)#\<^sub>\<Gamma>G)"
  shows "x \<notin> fst ` set xcs \<Longrightarrow> replace_in_g_subtyped \<Theta> \<B> ((x,b,c)#\<^sub>\<Gamma>G) xcs ((x,b,c)#\<^sub>\<Gamma>G')"
using assms proof(induct  rule: replace_in_g_subtyped.induct)
  case (replace_in_g_subtyped_nilI G)
  then show ?case 
    by (simp add: replace_in_g_subtyped.replace_in_g_subtyped_nilI)
next
  case (replace_in_g_subtyped_consI b' c' G x' \<Theta> \<B> c'' xcs' G')
  hence "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f G[x'\<longmapsto>c'']" using valid.simps wfC_wf by auto


  show ?case proof(rule replace_in_g_subtyped.replace_in_g_subtyped_consI)
    show  " Some (b', c') = lookup ((x, b,c) #\<^sub>\<Gamma> G) x'" using lookup.simps 
       fst_conv image_iff \<Gamma>_set_intros surj_pair replace_in_g_subtyped_consI by force
    show wbc: " \<Theta> ; \<B> ; (x, b, c) #\<^sub>\<Gamma> G  \<turnstile>\<^sub>w\<^sub>f c'' "  using wf_weakening \<open> \<Theta> ; \<B> ; G \<turnstile>\<^sub>w\<^sub>f c''\<close> \<open>\<Theta> ; \<B>  \<turnstile>\<^sub>w\<^sub>f (x, b, c) #\<^sub>\<Gamma> G \<close> by fastforce
    have  "x' \<noteq> x"  using replace_in_g_subtyped_consI by auto
    have wbc1: "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f (x, b, c) #\<^sub>\<Gamma> G[x'\<longmapsto>c'']" proof -
      have "(x, b, c) #\<^sub>\<Gamma> G[x'\<longmapsto>c''] = ((x, b, c) #\<^sub>\<Gamma> G)[x'\<longmapsto>c'']" using \<open>x' \<noteq> x\<close> using replace_in_g.simps by auto
      thus  ?thesis using wfG_replace_inside_rig \<open>\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f G[x'\<longmapsto>c'']\<close>  \<open>\<Theta> ; \<B>  \<turnstile>\<^sub>w\<^sub>f (x, b, c) #\<^sub>\<Gamma> G \<close> by fastforce   
    qed
    show  *: "\<Theta> ; \<B> ; replace_in_g ((x, b,c) #\<^sub>\<Gamma> G) x' c''  \<Turnstile> c'" 
    proof - 
      have "\<Theta> ; \<B> ; G[x'\<longmapsto>c'']  \<Turnstile> c'" using replace_in_g_subtyped_consI by auto
      thus ?thesis using replace_in_g_valid_weakening wbc1 \<open>x'\<noteq>x\<close> by auto     
    qed

    show  "replace_in_g_subtyped \<Theta> \<B> (replace_in_g ((x, b,c) #\<^sub>\<Gamma> G) x' c'') xcs' ((x, b,c) #\<^sub>\<Gamma> G')"  
      using replace_in_g_subtyped_consI wbc1 by auto
    show  "x' \<notin> fst ` set xcs'" 
      using replace_in_g_subtyped_consI by linarith
  qed
qed

lemma replace_in_g_split:
  fixes G::\<Gamma> 
  assumes "\<Gamma> = replace_in_g \<Gamma>' x c" and "\<Gamma>' =  G'@(x,b,c')#\<^sub>\<Gamma>G" and "wfG \<Theta> \<B> \<Gamma>'"
  shows "\<Gamma> =  G'@(x,b,c)#\<^sub>\<Gamma>G" 
using assms proof(induct G' arbitrary: G \<Gamma> \<Gamma>' rule: \<Gamma>_induct)
  case GNil
  then show ?case by simp
next
  case (GCons x1 b1 c1 \<Gamma>1)
  hence "x1 \<noteq> x"
    using wfG_cons_fresh2[of \<Theta> \<B> x1 b1 c1 \<Gamma>1 x b ] 
    using GCons.prems(2) GCons.prems(3) append_g.simps(2) by auto
  moreover hence *: "\<Theta> ; \<B>  \<turnstile>\<^sub>w\<^sub>f  (\<Gamma>1 @ (x, b, c') #\<^sub>\<Gamma> G)" using GCons append_g.simps wfG_elims by metis
  moreover hence "replace_in_g (\<Gamma>1 @ (x, b, c') #\<^sub>\<Gamma> G) x c = \<Gamma>1 @ (x, b, c) #\<^sub>\<Gamma> G" using GCons replace_in_g_inside[OF *, of c] by auto
  
  ultimately  show ?case using replace_in_g.simps(2)[of x1 b1 c1 " \<Gamma>1 @ (x, b, c') #\<^sub>\<Gamma> G" x c] GCons
    by (simp add: GCons.prems(1) GCons.prems(2)) 
qed

lemma replace_in_g_subtyped_split0:
  fixes G::\<Gamma> 
  assumes "replace_in_g_subtyped \<Theta> \<B> \<Gamma>'[(x,c)] \<Gamma>" and "\<Gamma>' =  G'@(x,b,c')#\<^sub>\<Gamma>G"  and "wfG \<Theta> \<B> \<Gamma>'"
  shows "\<Gamma> =  G'@(x,b,c)#\<^sub>\<Gamma>G" 
proof - 
  have "\<Gamma> = replace_in_g \<Gamma>' x c" using assms replace_in_g_subtyped.simps
    by (metis Pair_inject list.distinct(1) list.inject)
  thus ?thesis using assms replace_in_g_split by blast
qed

lemma replace_in_g_subtyped_split:
  assumes "Some (b, c') = lookup G x" and "\<Theta> ; \<B> ; replace_in_g G x c  \<Turnstile> c'" and "wfG \<Theta> \<B> G "
  shows "\<exists> \<Gamma> \<Gamma>'. G = \<Gamma>'@(x,b,c')#\<^sub>\<Gamma>\<Gamma> \<and> \<Theta> ; \<B> ; \<Gamma>'@(x,b,c)#\<^sub>\<Gamma>\<Gamma> \<Turnstile> c'"
proof -
  obtain \<Gamma> and \<Gamma>' where "G = \<Gamma>'@(x,b,c')#\<^sub>\<Gamma>\<Gamma>" using assms lookup_split by blast
  moreover hence  "replace_in_g G x c =  \<Gamma>'@(x,b,c)#\<^sub>\<Gamma>\<Gamma>" using replace_in_g_split assms by blast
  ultimately show ?thesis by (metis assms(2))
qed


section \<open>Validity and Subtyping\<close>

lemma wfC_replace_in_g:
  fixes c::c and c0::c
  assumes "\<Theta> ; \<B> ; \<Gamma>'@(x,b,c0')#\<^sub>\<Gamma>\<Gamma> \<turnstile>\<^sub>w\<^sub>f c" and "\<Theta> ; \<B> ; (x,b,TRUE)#\<^sub>\<Gamma>\<Gamma> \<turnstile>\<^sub>w\<^sub>f c0"
  shows "\<Theta> ; \<B> ; \<Gamma>' @ (x, b, c0) #\<^sub>\<Gamma> \<Gamma> \<turnstile>\<^sub>w\<^sub>f c"
using wf_replace_inside1(2) assms by auto 


lemma ctx_subtype_valid:
  assumes "\<Theta> ; \<B> ; \<Gamma>'@(x,b,c0')#\<^sub>\<Gamma>\<Gamma> \<Turnstile> c" and 
          "\<Theta> ; \<B> ; \<Gamma>'@(x,b,c0)#\<^sub>\<Gamma>\<Gamma> \<Turnstile> c0'"
  shows "\<Theta> ; \<B> ; \<Gamma>'@(x,b,c0)#\<^sub>\<Gamma>\<Gamma> \<Turnstile> c"
proof(rule validI)
  show "\<Theta> ; \<B> ; \<Gamma>' @ (x, b, c0) #\<^sub>\<Gamma> \<Gamma> \<turnstile>\<^sub>w\<^sub>f c" proof - 
    have  "\<Theta> ; \<B> ; \<Gamma>'@(x,b,c0')#\<^sub>\<Gamma>\<Gamma> \<turnstile>\<^sub>w\<^sub>f c" using valid.simps assms by auto
    moreover have "\<Theta> ; \<B> ; (x,b,TRUE)#\<^sub>\<Gamma>\<Gamma> \<turnstile>\<^sub>w\<^sub>f c0" proof -
      have "wfG \<Theta> \<B> (\<Gamma>'@(x,b,c0)#\<^sub>\<Gamma>\<Gamma>)" using assms valid.simps wfC_wf by auto
      hence "wfG \<Theta> \<B> ((x,b,c0)#\<^sub>\<Gamma>\<Gamma>)" using wfG_suffix by auto
      thus ?thesis using wfG_wfC by auto
    qed
    ultimately show ?thesis using assms wfC_replace_in_g by auto
  qed

  show "\<forall>i. wfI \<Theta> (\<Gamma>' @ (x, b, c0) #\<^sub>\<Gamma> \<Gamma>) i \<and> is_satis_g i (\<Gamma>' @ (x, b, c0) #\<^sub>\<Gamma> \<Gamma>) \<longrightarrow> is_satis i c" proof(rule,rule)
    fix i
    assume * : "wfI \<Theta> (\<Gamma>' @ (x, b, c0) #\<^sub>\<Gamma> \<Gamma>) i \<and> is_satis_g i (\<Gamma>' @ (x, b, c0) #\<^sub>\<Gamma> \<Gamma>) "

    hence "is_satis_g i (\<Gamma>'@(x, b, c0) #\<^sub>\<Gamma> \<Gamma>) \<and> wfI \<Theta> (\<Gamma>'@(x, b, c0) #\<^sub>\<Gamma> \<Gamma>) i" using is_satis_g_append wfI_suffix by metis
    moreover hence "is_satis i c0'" using valid.simps assms by presburger

    moreover have "is_satis_g i \<Gamma>'"  using is_satis_g_append * by simp
    ultimately have "is_satis_g i (\<Gamma>' @ (x, b, c0') #\<^sub>\<Gamma> \<Gamma>) " using is_satis_g_append by simp
    moreover have "wfI \<Theta> (\<Gamma>' @ (x, b, c0') #\<^sub>\<Gamma> \<Gamma>) i" using wfI_def wfI_suffix * wfI_def wfI_replace_inside by metis
    ultimately show  "is_satis i c" using assms valid.simps by metis
  qed
qed

lemma ctx_subtype_subtype:
  fixes \<Gamma>::\<Gamma>
  shows "\<Theta> ; \<B> ; G \<turnstile> t1 \<lesssim> t2 \<Longrightarrow> G = \<Gamma>'@(x,b0,c0')#\<^sub>\<Gamma>\<Gamma> \<Longrightarrow> \<Theta> ; \<B> ; \<Gamma>'@(x,b0,c0)#\<^sub>\<Gamma>\<Gamma> \<Turnstile> c0' \<Longrightarrow> \<Theta> ; \<B> ; \<Gamma>'@(x,b0,c0)#\<^sub>\<Gamma>\<Gamma> \<turnstile> t1 \<lesssim> t2"
proof(nominal_induct avoiding: c0 rule: subtype.strong_induct)

  case (subtype_baseI x' \<Theta> \<B> \<Gamma>'' z c z' c' b)
  let ?\<Gamma>c0 = "\<Gamma>'@(x,b0,c0)#\<^sub>\<Gamma>\<Gamma>" 
  have wb1:  "wfG \<Theta> \<B> ?\<Gamma>c0" using valid.simps wfC_wf   subtype_baseI by metis
  show ?case proof
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>   \<turnstile>\<^sub>w\<^sub>f \<lbrace> z : b  | c \<rbrace> \<close> using  wfT_replace_inside2[OF _ wb1] subtype_baseI by metis
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>   \<turnstile>\<^sub>w\<^sub>f \<lbrace> z' : b  | c' \<rbrace> \<close> using  wfT_replace_inside2[OF _ wb1] subtype_baseI by metis
    have "atom x' \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>" using fresh_prodN subtype_baseI fresh_replace_inside wb1 subtype_wf wfX_wfY by metis
    thus  \<open>atom x' \<sharp> (\<Theta>, \<B>, \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>,  z,  c , z' , c' )\<close>  using subtype_baseI fresh_prodN by metis
    have "\<Theta> ; \<B> ; ((x', b, c[z::=V_var x']\<^sub>v) #\<^sub>\<Gamma> \<Gamma>') @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<Turnstile> c'[z'::=V_var x']\<^sub>v " proof(rule ctx_subtype_valid)
      show 1: \<open>\<Theta> ; \<B> ; ((x', b, c[z::=V_var x']\<^sub>v) #\<^sub>\<Gamma> \<Gamma>') @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>  \<Turnstile> c'[z'::=V_var x']\<^sub>v \<close> 
        using  subtype_baseI append_g.simps subst_defs by metis
      have *:"\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f ((x', b, c[z::=V_var x']\<^sub>v) #\<^sub>\<Gamma> \<Gamma>') @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma> " proof(rule wfG_replace_inside2)
        show "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f ((x', b, c[z::=V_var x']\<^sub>v) #\<^sub>\<Gamma> \<Gamma>') @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>" 
          using * valid_wf_all wfC_wf 1 append_g.simps by metis
         show "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>" using wfG_suffix wb1 by auto
       qed
      moreover have "setG (\<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>) \<subseteq> setG (((x', b, c[z::=V_var x']\<^sub>v) #\<^sub>\<Gamma> \<Gamma>') @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>)" using setG.simps append_g.simps by auto
      ultimately show  \<open>\<Theta> ; \<B> ; ((x', b, c[z::=V_var x']\<^sub>v) #\<^sub>\<Gamma> \<Gamma>') @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<Turnstile> c0' \<close> using   valid_weakening subtype_baseI * by blast
    qed
    thus  \<open>\<Theta> ; \<B> ;  (x', b, c[z::=V_var x']\<^sub>v) #\<^sub>\<Gamma> \<Gamma>'  @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<Turnstile> c'[z'::=V_var x']\<^sub>v \<close> using append_g.simps subst_defs by simp     
  qed
qed


lemma ctx_subtype_subtype_rig:
  assumes   "replace_in_g_subtyped \<Theta>  \<B> \<Gamma>' [(x,c0)] \<Gamma>" and  "\<Theta> ; \<B> ; \<Gamma>' \<turnstile> t1 \<lesssim> t2"  
  shows "\<Theta> ; \<B> ; \<Gamma> \<turnstile> t1 \<lesssim> t2"
proof -
  have wf: "wfG \<Theta> \<B> \<Gamma>'" using subtype_g_wf assms by auto
  obtain b and c0' where  "Some (b, c0') = lookup \<Gamma>' x \<and> (\<Theta> ; \<B> ; replace_in_g \<Gamma>' x c0  \<Turnstile> c0')" using 
     replace_in_g_subtyped.simps[of  \<Theta> \<B> \<Gamma>' "[(x, c0)]" \<Gamma>] assms(1) 
    
   by (metis fst_conv list.inject list.set_intros(1) list.simps(15) not_Cons_self2 old.prod.exhaust prod.inject set_ConsD surj_pair)
  moreover then obtain G and G' where *: "\<Gamma>' = G'@(x,b,c0')#\<^sub>\<Gamma>G \<and> \<Theta> ; \<B> ; G'@(x,b,c0)#\<^sub>\<Gamma>G \<Turnstile> c0'" 
    using replace_in_g_subtyped_split[of b  c0' \<Gamma>' x \<Theta> \<B> c0] wf by metis

  ultimately show ?thesis using ctx_subtype_subtype 
    assms(1) assms(2) replace_in_g_subtyped_split0 subtype_g_wf  
    by (metis (no_types, lifting) local.wf replace_in_g_split)
qed


text \<open> We now prove versions of the @{text "ctx_subtype"} lemmas above using @{text "replace_in_g"}. First we do case where
the replace is just for a single variable (indicated by suffix rig) and then the general case for
multiple replacements (indicated by suffix rigs)\<close>

lemma ctx_subtype_subtype_rigs:
  assumes "replace_in_g_subtyped \<Theta> \<B> \<Gamma>' xcs \<Gamma>" and  "\<Theta> ; \<B> ; \<Gamma>' \<turnstile> t1 \<lesssim> t2"  
  shows "\<Theta> ; \<B> ; \<Gamma> \<turnstile> t1 \<lesssim> t2"
using assms proof(induct xcs arbitrary: \<Gamma> \<Gamma>'  )
  case Nil  
  moreover have "\<Gamma>' = \<Gamma>" using replace_in_g_subtyped_nilI 
    using calculation(1) by blast
  ultimately show ?case by auto
next
  case (Cons a xcs)

  then obtain x and c where "a=(x,c)" by fastforce
  then obtain b and c' where bc: "Some (b, c') = lookup \<Gamma>' x \<and>
         replace_in_g_subtyped \<Theta>  \<B> (replace_in_g \<Gamma>' x c) xcs \<Gamma> \<and>   \<Theta> ; \<B> ; \<Gamma>'  \<turnstile>\<^sub>w\<^sub>f c  \<and>
         x \<notin> fst ` set xcs \<and>  \<Theta> ; \<B> ; (replace_in_g \<Gamma>' x c)  \<Turnstile> c' " using replace_in_g_subtyped_elims(3)[of \<Theta> \<B> \<Gamma>' x c xcs \<Gamma>] Cons
    by (metis valid.simps)

  hence *: "replace_in_g_subtyped \<Theta> \<B> \<Gamma>' [(x,c)] (replace_in_g \<Gamma>' x c)" using replace_in_g_subtyped_consI 
    by (meson image_iff list.distinct(1) list.set_cases replace_in_g_subtyped_nilI)

  hence "\<Theta> ; \<B> ; (replace_in_g \<Gamma>' x c) \<turnstile>  t1 \<lesssim> t2"
    using  ctx_subtype_subtype_rig * assms Cons.prems(2) by auto

  moreover have "replace_in_g_subtyped \<Theta> \<B> (replace_in_g \<Gamma>' x c) xcs \<Gamma>" using Cons
    using bc by blast

  ultimately show ?case using Cons by blast
qed

lemma replace_in_g_inside_valid:
  assumes "replace_in_g_subtyped \<Theta> \<B> \<Gamma>' [(x,c0)] \<Gamma>" and "wfG \<Theta> \<B> \<Gamma>'"
  shows "\<exists>b c0' G G'. \<Gamma>' = G' @ (x,b,c0')#\<^sub>\<Gamma>G \<and>  \<Gamma> = G' @ (x,b,c0)#\<^sub>\<Gamma>G \<and> \<Theta> ; \<B> ; G'@ (x,b,c0)#\<^sub>\<Gamma>G  \<Turnstile> c0'"
 proof - 
  obtain b and c0' where  bc: "Some (b, c0') = lookup \<Gamma>' x \<and> \<Theta> ; \<B> ; replace_in_g \<Gamma>' x c0  \<Turnstile> c0'" using 
     replace_in_g_subtyped.simps[of  \<Theta> \<B> \<Gamma>' "[(x, c0)]" \<Gamma>] assms(1) 
    by (metis fst_conv list.inject list.set_intros(1) list.simps(15) not_Cons_self2 old.prod.exhaust prod.inject set_ConsD surj_pair)
  then obtain G and G' where *: "\<Gamma>' = G'@(x,b,c0')#\<^sub>\<Gamma>G \<and> \<Theta> ; \<B> ; G'@(x,b,c0)#\<^sub>\<Gamma>G \<Turnstile> c0'" using replace_in_g_subtyped_split[of b c0' \<Gamma>' x \<Theta> \<B> c0] assms
    by metis
  thus ?thesis using replace_in_g_inside bc
    using assms(1) assms(2) by blast
qed

lemma replace_in_g_valid:
  assumes "\<Theta> ; \<B>  \<turnstile> G \<langle> xcs \<rangle> \<leadsto> G'" and  "\<Theta> ; \<B> ; G  \<Turnstile> c "
  shows  \<open>\<Theta> ; \<B> ; G'  \<Turnstile> c \<close>
using assms proof(induct rule: replace_in_g_subtyped.inducts)
  case (replace_in_g_subtyped_nilI \<Theta> \<B> G)
  then show ?case by auto
next
  case (replace_in_g_subtyped_consI b c1 G x \<Theta> \<B> c2 xcs G')
  hence "\<Theta> ; \<B> ; G[x\<longmapsto>c2]  \<Turnstile> c" 
    by (metis ctx_subtype_valid replace_in_g_split replace_in_g_subtyped_split valid_g_wf)
  then show ?case using replace_in_g_subtyped_consI by auto
qed

 
section \<open>Literals\<close>

(*
lemma ctx_subtype_l2:
  fixes l::l
  assumes
        "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0')#\<^sub>\<Gamma>\<Gamma>) \<turnstile> l \<Rightarrow> t1" and 
        "\<Theta> ; \<B> ; \<Gamma>'@(x,b0,c0)#\<^sub>\<Gamma>\<Gamma> \<Turnstile> c0'" 
  shows "\<exists>t2.  \<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> l \<Rightarrow> t2 \<and>  \<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> t2 \<lesssim> t1"
proof -
  have "wfG \<Theta> \<B> (\<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>))"proof -
    have "wfG \<Theta> \<B> (\<Gamma>'@((x,b0,c0')#\<^sub>\<Gamma>\<Gamma>))" using infer_l_wf assms  by metis
    thus ?thesis using wfG_inside_valid2 assms  by simp
  qed
  hence  "\<Theta>; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> l \<Rightarrow> t1" using infer_l_wf assms infer_l_any by metis
  moreover hence "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> t1 \<lesssim> t1" 
    using subtype_reflI2 infer_l_wf by presburger
  ultimately show ?thesis by metis
qed
*)
section \<open>Values\<close>

lemma lookup_inside_unique_b[simp]:
  assumes "\<Theta> ; B \<turnstile>\<^sub>w\<^sub>f (\<Gamma>'@(x,b0,c0)#\<^sub>\<Gamma>\<Gamma>)" and "\<Theta> ; B \<turnstile>\<^sub>w\<^sub>f (\<Gamma>'@(x,b0,c0')#\<^sub>\<Gamma>\<Gamma>)"
    and  "Some (b, c) = lookup (\<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>) y" and  "Some (b0,c0) = lookup (\<Gamma>'@((x,b0,c0))#\<^sub>\<Gamma>\<Gamma>) x" and "x=y"
  shows "b = b0"
  by (metis assms(2) assms(3) assms(5) lookup_inside_wf old.prod.exhaust option.inject prod.inject)



text \<open> I think using rule induction for values and expressions is only going to save us 
from doing the elimination step\<close>
lemma ctx_subtype_v:
  fixes v::v
  assumes
          "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0')#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v \<Rightarrow> t1" and   "\<Theta> ; \<B> ; \<Gamma>'@(x,b0,c0)#\<^sub>\<Gamma>\<Gamma> \<Turnstile> c0'" 
  shows "\<exists>t2.  \<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v \<Rightarrow> t2 \<and>  \<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> t2 \<lesssim> t1"
using assms proof(nominal_induct "v" arbitrary: t1   rule: v.strong_induct)
  case (V_lit l)
  have "  \<turnstile> l \<Rightarrow> t1" using V_lit infer_v_elims by force
  hence "\<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> V_lit l \<Rightarrow> t1"
    using infer_v_litI  V_lit valid.simps wfC_wf by metis
  moreover hence "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> t1 \<lesssim> t1" using  infer_v_wf 
    by (meson subtype_reflI2)
  ultimately show ?case using * by metis
next
  case (V_var y)
  have wfg0: "wfG \<Theta> \<B> (\<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>)" using infer_v_wf V_var by fast
  hence wfg1: "wfG \<Theta> \<B> (\<Gamma>'@(x,b0,c0)#\<^sub>\<Gamma>\<Gamma>)" using V_var wfG_inside_valid2 by metis
 
  obtain z and b and c where zb: "t1 =  (\<lbrace> z : b | C_eq (CE_val (V_var z)) (CE_val (V_var y)) \<rbrace>) \<and> 
                   atom z \<sharp> y  \<and> atom z \<sharp> (\<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>) \<and> Some (b, c) = lookup (\<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>) y"
    using infer_v_elims(1)[OF V_var(1)] by metis
  hence lu1: "Some (b, c) = lookup (\<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>) y" by auto

  show ?case proof(cases "x = y")
    case True
    have lu: "Some (b0,c0) = lookup (\<Gamma>'@((x,b0,c0))#\<^sub>\<Gamma>\<Gamma>) x" using lookup_inside_wf  wfg1 by metis
    moreover hence "b0 = b" using lu1 True  lookup_inside_unique_b 
      using \<open>wfG \<Theta> \<B> (\<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>)\<close> wfg1  by metis
    moreover have "atom z \<sharp> x" using True zb by simp
    moreover have "atom z \<sharp>  \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>)" using zb fresh_replace_inside  wfg0 wfg1 by metis
    ultimately have  "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> (V_var x) \<Rightarrow> (\<lbrace> z : b | C_eq (CE_val (V_var z)) (CE_val (V_var x)) \<rbrace>)"
      using infer_v_varI  wfg1 by metis
    thus ?thesis 
      using True infer_v_t_wf subtype_reflI2 zb by metis
  next
    case False
    then obtain b1 and c1 where bc: "Some (b1,c1) = lookup (\<Gamma>'@((x,b0,c0')#\<^sub>\<Gamma>\<Gamma>)) y" 
      using infer_v_elims V_var by meson

    have  "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> (V_var y) \<Rightarrow> (\<lbrace> z : b1 | C_eq (CE_val (V_var z)) (CE_val (V_var y)) \<rbrace>)" proof
      show "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>" using  wfg1  by auto      
      show "Some (b1, c1) = lookup (\<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>) y"  using lookup_inside2 False bc by blast
      show "atom z \<sharp> y" using zb by auto
      show "atom z \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>" using fresh_replace_inside wfg0 wfg1  zb by metis
    qed
     
    thus ?thesis 
      using subtype_reflI2 infer_v_t_wf
      by (metis Pair_inject V_var.prems(1) bc infer_v_elims(1) option.inject type_eq_subst_eq2(2) zb)
  qed
next
  case (V_pair v1 v2)

  then obtain tv1 and tv2  and  z where  tt1: "\<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v1 \<Rightarrow> tv1 \<and>  
        \<Theta> ;  \<B> ; \<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v2 \<Rightarrow> tv2 \<and> t1 = (\<lbrace> z : B_pair (b_of tv1) (b_of tv2)  | 
                          CE_val (V_var z)  ==  CE_val (V_pair v1 v2)  \<rbrace>) \<and> atom z \<sharp> (v1,v2)"
    using infer_v_pair2E by presburger
  obtain tv1' where t1: "\<Theta> ;  \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v1 \<Rightarrow> tv1' \<and>   \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> tv1' \<lesssim> tv1" using tt1 V_pair by fast
  moreover obtain tv2' where t2: "\<Theta> ;  \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v2 \<Rightarrow> tv2' \<and>   \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> tv2' \<lesssim> tv2" using tt1 V_pair by fast
  ultimately obtain t' and z' where tt2: "\<Theta> ; \<B> ;  \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> V_pair v1 v2 \<Rightarrow> t' \<and> 
             t' = (\<lbrace> z' : B_pair (b_of tv1') (b_of tv2')  | CE_val (V_var z')  ==  CE_val (V_pair v1 v2)  \<rbrace>) \<and> atom z' \<sharp> (v1,v2)"
    using  infer_v_pair2I_zbc  t1 t2 by metis
  
  hence "t1 = t'" proof - 
    have "t' = (\<lbrace> z' : B_pair (b_of tv1') (b_of tv2')  | CE_val (V_var z')  ==  CE_val (V_pair v1 v2)  \<rbrace>)" using tt2 by auto
    moreover have "t1 =  (\<lbrace> z : B_pair (b_of tv1) (b_of tv2)  | CE_val (V_var z)  ==  CE_val (V_pair v1 v2)  \<rbrace>)" using tt1 by auto
    moreover have "b_of tv1 = b_of tv1' \<and> b_of tv2 = b_of tv2'" 
      using t1 t2  by (metis subtype_eq_base2)
    moreover have "atom z \<sharp> CE_val (V_pair v1 v2) \<and> atom z' \<sharp> CE_val (V_pair v1 v2)" using tt1 tt2 ce.fresh v.fresh by force
    ultimately show ?thesis using type_e_eq by presburger 
  qed

  moreover have "wfT \<Theta> \<B> (\<Gamma>' @ (x, b0, c0)#\<^sub>\<Gamma>\<Gamma>) t'" using t1 infer_v_t_wf tt2 by metis
  ultimately have " \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0)#\<^sub>\<Gamma>\<Gamma> \<turnstile> t' \<lesssim> t1" using subtype_reflI
    using subtype_reflI2 by blast

  then show ?case using tt2 by meson

next
  case (V_consp s dc b' v')

  obtain z::x where zf: "atom z \<sharp>  (\<Theta>, \<B>, \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>, v', b',V_consp s dc b' v')" using obtain_fresh by metis
  
  from V_consp(2) V_consp(1)  V_consp(3) zf have t2:"\<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma> \<turnstile> V_consp s dc b' v' \<Rightarrow> \<lbrace> z : B_app s b' |  [ [ z ]\<^sup>v ]\<^sup>c\<^sup>e  ==  [ V_consp s dc b' v' ]\<^sup>c\<^sup>e  \<rbrace>"
  proof(nominal_induct " \<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>"  "V_consp s dc b' v'" t1 avoiding: c0 arbitrary: t1   rule: infer_v.strong_induct)
    case (infer_v_conspI bv dclist \<Theta> tc \<B> tv zz)
   obtain tv2 where *:" \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma> \<turnstile> v' \<Rightarrow> tv2 \<and> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> tv2 \<lesssim> tv" 
       using infer_v_conspI(17) infer_v_conspI by metis
     thm ctx_subtype_subtype infer_v_conspI(18)
    show ?case proof
     show \<open>AF_typedef_poly s bv dclist \<in> set \<Theta>\<close> using infer_v_conspI by auto
     show \<open>(dc, tc) \<in> set dclist\<close> using infer_v_conspI by auto
     show \<open> \<Theta> ; \<B>  \<turnstile>\<^sub>w\<^sub>f b' \<close> using infer_v_conspI by auto
     show iv: \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma> \<turnstile> v' \<Rightarrow> tv2\<close> using * by auto

     have "\<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> tv \<lesssim> tc[bv::=b']\<^sub>\<tau>\<^sub>b"
       using infer_v_conspI infer_v_conspI(18) ctx_subtype_subtype by metis

     thus \<open>\<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> tv2 \<lesssim> tc[bv::=b']\<^sub>\<tau>\<^sub>b\<close> using * subtype_trans by metis
      
     show \<open>atom z \<sharp> (\<Theta>, \<B>, \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>, v', b')\<close> using fresh_prodN infer_v_conspI by metis
     
     have " atom bv \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>"  unfolding fresh_append_g fresh_GCons fresh_prod3 fresh_append_g
       using fresh_append_g fresh_GCons fresh_prod3 fresh_append_g \<open> atom bv \<sharp> \<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>\<close>  infer_v_conspI by metis
             
     thus \<open>atom bv \<sharp> (\<Theta>, \<B>, \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>, v', b')\<close>  using infer_v_conspI fresh_prodN by metis
    
   qed
 qed

  let ?t2 =  "\<lbrace> z : B_app s b' |  [ [ z ]\<^sup>v ]\<^sup>c\<^sup>e  ==  [ V_consp s dc b' v' ]\<^sup>c\<^sup>e  \<rbrace>"

  obtain z1 and b1 where  t1:"t1 = \<lbrace> z1 : b1 |  [ [ z1 ]\<^sup>v ]\<^sup>c\<^sup>e  ==  [ V_consp s dc b' v' ]\<^sup>c\<^sup>e  \<rbrace> \<and> atom z1 \<sharp>  V_consp s dc b' v'  " 
    using V_consp(2) infer_v_form  by metis
  moreover then have b1:"b1 =  B_app s b'" using infer_v_form_consp V_consp b_of.simps by metis

  let ?t1 = "\<lbrace> z1 : B_app s b' |  [ [ z1 ]\<^sup>v ]\<^sup>c\<^sup>e  ==  [ V_consp s dc b' v' ]\<^sup>c\<^sup>e  \<rbrace>"

  have "?t1 = ?t2" using type_e_eq zf t1 ce.fresh fresh_prodN by metis

  moreover have " \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>   \<turnstile>\<^sub>w\<^sub>f \<lbrace> z : B_app s b'  | [ [ z ]\<^sup>v ]\<^sup>c\<^sup>e  ==  [ V_consp s dc b' v' ]\<^sup>c\<^sup>e  \<rbrace> " 
    using t2 using infer_v_wf by auto
  ultimately have " \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> ?t2 \<lesssim> ?t1" using subtype_reflI by metis

  moreover have "?t1 = t1" using t1 b1 by auto
  ultimately show ?case using t2 by metis
  
next
  case (V_cons s dc v')

  obtain xa and b and c and z' and c' and z and dclist where tt: "
    t1 = (\<lbrace> z : B_id s  | CE_val (V_var z)  ==  CE_val (V_cons s dc v')  \<rbrace>) \<and>
    AF_typedef s dclist \<in> set \<Theta> \<and>
      (dc, \<lbrace> xa : b  | c \<rbrace>) \<in> set dclist \<and> atom z \<sharp> \<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma> \<and>
     \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v' \<Rightarrow> \<lbrace> z' : b  | c' \<rbrace> \<and>  \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>  \<turnstile> \<lbrace> z' : b  | c' \<rbrace> \<lesssim> \<lbrace> xa : b  | c \<rbrace> \<and> atom z \<sharp> v' "
    using infer_v_elims(4)[OF V_cons(2)] by metis

  hence "\<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v' \<Rightarrow> \<lbrace> z' : b  | c' \<rbrace>" by linarith
  then obtain t2 where *:" \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v' \<Rightarrow> t2 \<and>   \<Theta> ; \<B> ; \<Gamma>' @ ((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> t2 \<lesssim>  \<lbrace> z' : b  | c' \<rbrace>" 
    using V_cons by presburger
  obtain z3 and b3 and c3 where t2: "t2 = (\<lbrace> z3 : b3 |c3 \<rbrace>)" using obtain_fresh_z by meson
  hence beq: "b = b3" using subtype_eq_base * by blast

  have " \<Theta>; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> \<lbrace> z' : b  | c' \<rbrace> \<lesssim> \<lbrace> xa : b  | c \<rbrace>" using tt ctx_subtype_subtype V_cons by metis

  hence tsub: " \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> t2 \<lesssim> \<lbrace> xa : b  | c \<rbrace>" 
    using subtype_trans * by blast

  have "wfTh \<Theta>" using tt infer_v_wf by auto
  moreover have "AF_typedef s dclist \<in> set \<Theta> \<and> (dc, \<lbrace> xa : b  | c \<rbrace>) \<in> set dclist" using tt by auto
  moreover have "\<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v' \<Rightarrow> \<lbrace> z3 : b  | c3 \<rbrace>" using * t2 beq by blast
  moreover have " \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> \<lbrace> z3 : b  | c3 \<rbrace> \<lesssim> \<lbrace> xa : b  | c \<rbrace>" using t2 tsub beq by blast
  moreover have "atom z \<sharp> v'" using tt by auto
  moreover have "atom z \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>" using fresh_replace_inside tt infer_v_wf * by metis
  ultimately have "\<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> V_cons s dc v' \<Rightarrow> 
            \<lbrace> z : B_id s  | CE_val (V_var z)  ==  CE_val (V_cons s dc v')  \<rbrace>" 
    using infer_v_consI by metis

  hence **: " \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> V_cons s dc v' \<Rightarrow> t1" 
    using tt by argo

  moreover have " \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> t1 \<lesssim> t1" proof - 
    have "wfT \<Theta> \<B> (\<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>) t1" using ** infer_v_wf by metis
    thus ?thesis using subtype_reflI2 by presburger
  qed
  ultimately show ?case by metis
qed

lemma ctx_subtype_v_eq:
  fixes v::v
  assumes
          "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0')#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v \<Rightarrow> t1" and 
          " \<Theta> ; \<B> ; \<Gamma>'@(x,b0,c0)#\<^sub>\<Gamma>\<Gamma> \<Turnstile> c0'" 
        shows "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v \<Rightarrow> t1"
proof - 
  obtain t1' where "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v \<Rightarrow> t1'" using ctx_subtype_v assms by metis
  moreover have "replace_in_g (\<Gamma>'@((x,b0,c0')#\<^sub>\<Gamma>\<Gamma>)) x c0 =  \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>)" using replace_in_g_inside infer_v_wf assms by metis
  ultimately show ?thesis using infer_v_uniqueness_rig assms by metis
qed


lemma ctx_subtype_check_v_eq:
  assumes  "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0')#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v \<Leftarrow> t1" and " \<Theta> ; \<B> ; \<Gamma>'@(x,b0,c0)#\<^sub>\<Gamma>\<Gamma> \<Turnstile> c0'"
  shows "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v \<Leftarrow> t1"
proof - 
  obtain t2 where t2: "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0')#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v \<Rightarrow> t2 \<and>   \<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0')#\<^sub>\<Gamma>\<Gamma>) \<turnstile> t2 \<lesssim> t1" 
    using check_v_elims assms by blast
  hence t3: "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>)  \<turnstile> v \<Rightarrow> t2"
    using assms ctx_subtype_v_eq by blast

  have "\<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>)  \<turnstile> v \<Rightarrow> t2" using t3 by auto
  moreover have " \<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>)  \<turnstile> t2 \<lesssim> t1" proof -

    have " \<Theta> ; \<B> ; \<Gamma>'@((x,b0,c0')#\<^sub>\<Gamma>\<Gamma>) \<turnstile> t2 \<lesssim> t1" using t2 by auto
    thus  ?thesis using subtype_trans
      using assms(2) ctx_subtype_subtype by blast
  qed
  ultimately show ?thesis using check_v.intros by presburger 
qed

text \<open> Basically the same as @{text "ctx_subtype_v_eq"} but in a different form\<close>
lemma ctx_subtype_v_rig_eq:
  fixes v::v
  assumes "replace_in_g_subtyped  \<Theta> \<B> \<Gamma>' [(x,c0)] \<Gamma>" and  
          "\<Theta> ; \<B> ; \<Gamma>'  \<turnstile> v \<Rightarrow> t1" 
        shows "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> t1"
proof - 
  obtain b and c0' and G and G' where "\<Gamma>' = G' @ (x,b,c0')#\<^sub>\<Gamma>G \<and>  \<Gamma> = G' @ (x,b,c0)#\<^sub>\<Gamma>G \<and>  \<Theta> ; \<B> ; G'@ (x,b,c0)#\<^sub>\<Gamma>G  \<Turnstile> c0'"
    using assms replace_in_g_inside_valid  infer_v_wf by metis
  thus ?thesis using ctx_subtype_v_eq[of \<Theta> \<B> G' x b c0' G v t1 c0] assms by simp
qed

lemma ctx_subtype_v_rigs_eq:
  fixes v::v
  assumes "replace_in_g_subtyped \<Theta> \<B> \<Gamma>' xcs \<Gamma>" and  
          "\<Theta> ; \<B> ; \<Gamma>'  \<turnstile> v \<Rightarrow> t1" 
        shows "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> t1"
using assms proof(induct xcs arbitrary: \<Gamma> \<Gamma>' t1 )
case Nil
  then show ?case by auto
next
  case (Cons a xcs)
  then obtain x and c where "a=(x,c)" by fastforce

  then obtain b and c' where bc: "Some (b, c') = lookup \<Gamma>' x \<and>
         replace_in_g_subtyped  \<Theta> \<B> (replace_in_g \<Gamma>' x c) xcs \<Gamma> \<and>  \<Theta> ; \<B> ; \<Gamma>'  \<turnstile>\<^sub>w\<^sub>f c \<and>
         x \<notin> fst ` set xcs \<and>   \<Theta> ; \<B> ; (replace_in_g \<Gamma>' x c)  \<Turnstile> c' "   
    using replace_in_g_subtyped_elims(3)[of  \<Theta> \<B> \<Gamma>' x c xcs \<Gamma>] Cons  by (metis valid.simps)

  hence *: "replace_in_g_subtyped  \<Theta> \<B> \<Gamma>' [(x,c)] (replace_in_g \<Gamma>' x c)" using replace_in_g_subtyped_consI 
    by (meson image_iff list.distinct(1) list.set_cases replace_in_g_subtyped_nilI)
  hence   t2: "\<Theta> ; \<B> ; (replace_in_g \<Gamma>' x c) \<turnstile> v \<Rightarrow> t1 " using ctx_subtype_v_rig_eq[OF * Cons(3)] by blast
  moreover have **: "replace_in_g_subtyped  \<Theta> \<B> (replace_in_g \<Gamma>' x c) xcs \<Gamma>" using bc by auto
  ultimately have  t2': "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> t1" using Cons by blast
  thus ?case by blast
qed


lemma ctx_subtype_check_v_rigs_eq:
  assumes "replace_in_g_subtyped \<Theta> \<B> \<Gamma>' xcs \<Gamma>" and  
          "\<Theta> ; \<B> ; \<Gamma>'  \<turnstile> v \<Leftarrow> t1" 
        shows "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Leftarrow> t1"
proof - 
  obtain t2 where  "\<Theta> ; \<B> ; \<Gamma>'  \<turnstile> v \<Rightarrow> t2 \<and>  \<Theta> ; \<B> ; \<Gamma>' \<turnstile> t2 \<lesssim> t1" using check_v_elims assms by fast
  hence "\<Theta> ; \<B> ; \<Gamma>  \<turnstile> v \<Rightarrow> t2 \<and>  \<Theta> ; \<B> ; \<Gamma> \<turnstile> t2 \<lesssim> t1" using ctx_subtype_v_rigs_eq ctx_subtype_subtype_rigs 
    using assms(1) by blast
  thus ?thesis 
    using check_v_subtypeI by blast
qed


section \<open>Expressions\<close>

lemma valid_wfC:
  fixes c0::c
  assumes  "\<Theta> ; \<B> ; \<Gamma>'@(x,b0,c0)#\<^sub>\<Gamma>\<Gamma> \<Turnstile> c0'" 
  shows "\<Theta> ; \<B> ; (x, b0, TRUE) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f c0"
  using  wfG_elim2 valid.simps wfG_suffix 
  using assms valid_g_wf by metis

lemma ctx_subtype_e_eq:
  fixes G::\<Gamma>
  assumes
          "\<Theta> ; \<Phi> ; \<B> ; G ; \<Delta> \<turnstile> e \<Rightarrow> t1" and "G =  \<Gamma>'@((x,b0,c0')#\<^sub>\<Gamma>\<Gamma>)"
          "\<Theta> ; \<B> ; \<Gamma>'@(x,b0,c0)#\<^sub>\<Gamma>\<Gamma> \<Turnstile> c0'" 
        shows "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>'@((x,b0,c0)#\<^sub>\<Gamma>\<Gamma>) ; \<Delta> \<turnstile> e \<Rightarrow> t1"
using assms proof(nominal_induct t1 avoiding: c0 rule: infer_e.strong_induct)
  case (infer_e_valI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v \<tau>)
  show ?case proof
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<Delta> \<close> using wf_replace_inside2(6) valid_wfC infer_e_valI by auto
    show \<open> \<Theta>  \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using infer_e_valI by auto
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v \<Rightarrow> \<tau>\<close> using infer_e_valI ctx_subtype_v_eq by auto
  qed
next
  case (infer_e_plusI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v1 z1 c1 v2 z2 c2 z3)
  show ?case proof 
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<Delta> \<close> using wf_replace_inside2(6) valid_wfC infer_e_plusI by auto
    show \<open> \<Theta>  \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close>  using infer_e_plusI by auto
    show *:\<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v1 \<Rightarrow> \<lbrace> z1 : B_int  | c1 \<rbrace>\<close> using infer_e_plusI ctx_subtype_v_eq by auto
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v2 \<Rightarrow> \<lbrace> z2 : B_int  | c2 \<rbrace>\<close> using infer_e_plusI ctx_subtype_v_eq by auto
    show \<open>atom z3 \<sharp> AE_op Plus v1 v2\<close> using infer_e_plusI by auto
    show   \<open>atom z3 \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>\<close> using * infer_e_plusI fresh_replace_inside  infer_v_wf  by metis
  qed
next
  case (infer_e_leqI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v1 z1 c1 v2 z2 c2 z3)
    show ?case proof 
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<Delta> \<close> using wf_replace_inside2(6) valid_wfC infer_e_leqI by auto
    show \<open> \<Theta>  \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close>  using infer_e_leqI by auto
    show *:\<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v1 \<Rightarrow> \<lbrace> z1 : B_int  | c1 \<rbrace>\<close> using infer_e_leqI ctx_subtype_v_eq by auto
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v2 \<Rightarrow> \<lbrace> z2 : B_int  | c2 \<rbrace>\<close> using infer_e_leqI ctx_subtype_v_eq by auto
    show \<open>atom z3 \<sharp> AE_op LEq v1 v2\<close> using infer_e_leqI by auto
    show   \<open>atom z3 \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>\<close> using * infer_e_leqI fresh_replace_inside  infer_v_wf  by metis
  qed
next
  case (infer_e_appI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> f x' b c \<tau>' s' v \<tau>)
  show ?case proof
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<Delta> \<close> using wf_replace_inside2(6) valid_wfC infer_e_appI by auto
    show \<open> \<Theta>  \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using  infer_e_appI by auto
    show \<open>Some (AF_fundef f (AF_fun_typ_none (AF_fun_typ x' b c \<tau>' s'))) = lookup_fun \<Phi> f\<close>  using infer_e_appI by auto
    show \<open>\<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v \<Leftarrow> \<lbrace> x' : b  | c \<rbrace>\<close> using infer_e_appI ctx_subtype_check_v_eq by auto
    thus \<open>atom x' \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>\<close> using infer_e_appI fresh_replace_inside[of \<Theta> \<B> \<Gamma>' x b0 c0' \<Gamma> c0 x']  infer_v_wf by auto
    show \<open>\<tau>'[x'::=v]\<^sub>v = \<tau>\<close> using infer_e_appI by auto
  qed
next
  case (infer_e_appPI \<Theta> \<B> \<Gamma>1 \<Delta> \<Phi> b' f bv x1 b c \<tau>' s' v \<tau>)
  show ?case proof
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta> \<close> using wf_replace_inside2(6) valid_wfC infer_e_appPI by auto
    show \<open> \<Theta>  \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using infer_e_appPI by auto
    show \<open> \<Theta> ; \<B>  \<turnstile>\<^sub>w\<^sub>f b' \<close> using infer_e_appPI by auto
    show \<open>Some (AF_fundef f (AF_fun_typ_some bv (AF_fun_typ x1 b c \<tau>' s'))) = lookup_fun \<Phi> f\<close> using infer_e_appPI by auto
    show \<open>\<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v \<Leftarrow> \<lbrace> x1 : b[bv::=b']\<^sub>b  | c[bv::=b']\<^sub>b \<rbrace>\<close> using infer_e_appPI  ctx_subtype_check_v_eq subst_defs by auto
    thus  \<open>atom x1 \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>\<close> using  fresh_replace_inside[of \<Theta> \<B> \<Gamma>' x b0 c0' \<Gamma>  c0 x1 ] infer_v_wf infer_e_appPI by auto
    show \<open>\<tau>'[bv::=b']\<^sub>b[x1::=v]\<^sub>v = \<tau>\<close> using infer_e_appPI by auto
    have "atom bv \<sharp> \<Gamma>' @ (x, b0, c0') #\<^sub>\<Gamma> \<Gamma>" using infer_e_appPI by metis
    hence "atom bv \<sharp>  \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>" 
      unfolding fresh_append_g fresh_GCons fresh_prod3 using  \<open>atom bv \<sharp> c0 \<close> fresh_append_g by metis
    thus  \<open>atom bv \<sharp>  (\<Theta>, \<Phi>, \<B>, \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>, \<Delta>, b', v, \<tau>)\<close> using infer_e_appPI by auto
  qed
next
  case (infer_e_fstI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v z' b1 b2 c z)
  show ?case proof 
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<Delta> \<close> using wf_replace_inside2(6) valid_wfC infer_e_fstI by auto
    show \<open> \<Theta> \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using infer_e_fstI by auto
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v \<Rightarrow> \<lbrace> z' : B_pair b1 b2  | c \<rbrace>\<close> using infer_e_fstI ctx_subtype_v_eq by auto
    thus \<open>atom z \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>\<close> using infer_e_fstI fresh_replace_inside[of \<Theta> \<B> \<Gamma>' x b0 c0' \<Gamma> c0 z]  infer_v_wf by auto
    show \<open>atom z \<sharp> AE_fst v\<close> using infer_e_fstI by auto
  qed
next
  case (infer_e_sndI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v z' b1 b2 c z)
  show ?case proof 
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<Delta> \<close> using wf_replace_inside2(6) valid_wfC infer_e_sndI by auto
    show \<open> \<Theta> \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using infer_e_sndI by auto
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v \<Rightarrow> \<lbrace> z' : B_pair b1 b2  | c \<rbrace>\<close> using infer_e_sndI ctx_subtype_v_eq by auto
    thus \<open>atom z \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>\<close> using infer_e_sndI fresh_replace_inside[of \<Theta> \<B> \<Gamma>' x b0 c0' \<Gamma> c0 z]  infer_v_wf by auto
    show \<open>atom z \<sharp> AE_snd v\<close> using infer_e_sndI by auto
  qed
next
  case (infer_e_lenI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v z' c z)
  show ?case proof 
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<Delta> \<close> using wf_replace_inside2(6) valid_wfC infer_e_lenI by auto
    show \<open> \<Theta> \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using infer_e_lenI by auto
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v \<Rightarrow> \<lbrace> z' : B_bitvec  | c \<rbrace>\<close> using infer_e_lenI ctx_subtype_v_eq by auto
    thus \<open>atom z \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>\<close> using infer_e_lenI fresh_replace_inside[of \<Theta> \<B> \<Gamma>' x b0 c0' \<Gamma> c0 z]  infer_v_wf by auto
    show \<open>atom z \<sharp> AE_len v\<close> using infer_e_lenI by auto
  qed
next
  case (infer_e_mvarI \<Theta> \<B> \<Gamma>'' \<Phi> \<Delta> u \<tau>)
  show ?case proof 
    show "\<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<Delta>"   using wf_replace_inside2(6) valid_wfC infer_e_mvarI by auto
    thus "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>" using infer_e_mvarI fresh_replace_inside  wfD_wf   by blast 
    show "\<Theta> \<turnstile>\<^sub>w\<^sub>f \<Phi> "  using infer_e_mvarI by auto
    show "(u, \<tau>) \<in> setD \<Delta>" using infer_e_mvarI by auto
  qed
next
  case (infer_e_concatI \<Theta>  \<B> \<Gamma>'' \<Delta> \<Phi> v1 z1 c1 v2 z2 c2 z3)
  show ?case proof 
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<Delta> \<close> using wf_replace_inside2(6) valid_wfC infer_e_concatI by auto
    thus  \<open>atom z3 \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>\<close> using infer_e_concatI fresh_replace_inside[of \<Theta> \<B> \<Gamma>' x b0 c0' \<Gamma> c0 z3]  infer_v_wf wfX_wfY by metis
    show \<open> \<Theta> \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using infer_e_concatI by auto
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v1 \<Rightarrow> \<lbrace> z1 : B_bitvec  | c1 \<rbrace>\<close> using infer_e_concatI ctx_subtype_v_eq by auto
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v2 \<Rightarrow> \<lbrace> z2 : B_bitvec  | c2 \<rbrace>\<close> using infer_e_concatI ctx_subtype_v_eq by auto
    show \<open>atom z3 \<sharp> AE_concat v1 v2\<close> using infer_e_concatI by auto  
  qed
next
  case (infer_e_splitI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v1 z1 c1 v2 z2 z3)
  show ?case proof
    show *:\<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta> \<close> using wf_replace_inside2(6) valid_wfC infer_e_splitI by auto  
    show \<open> \<Theta>  \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using infer_e_splitI by auto
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma> \<turnstile> v1 \<Rightarrow> \<lbrace> z1 : B_bitvec  | c1 \<rbrace>\<close> using infer_e_splitI  ctx_subtype_v_eq by auto
    show \<open>\<Theta> ; \<B> ; \<Gamma>' @
                 (x, b0, c0) #\<^sub>\<Gamma>
                 \<Gamma>  \<turnstile> v2 \<Leftarrow> \<lbrace> z2 : B_int  | [ leq [ [ L_num 0 ]\<^sup>v ]\<^sup>c\<^sup>e [ [ z2 ]\<^sup>v ]\<^sup>c\<^sup>e ]\<^sup>c\<^sup>e  ==  [ [ L_true ]\<^sup>v ]\<^sup>c\<^sup>e AND
                                 [ leq [ [ z2 ]\<^sup>v ]\<^sup>c\<^sup>e [| [ v1 ]\<^sup>c\<^sup>e |]\<^sup>c\<^sup>e ]\<^sup>c\<^sup>e  ==  [ [ L_true ]\<^sup>v ]\<^sup>c\<^sup>e   \<rbrace>\<close> 
               using infer_e_splitI  ctx_subtype_check_v_eq by auto

    show  \<open>atom z1 \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>\<close> using  fresh_replace_inside[of \<Theta> \<B> \<Gamma>' x b0 c0' \<Gamma> c0 z1] infer_e_splitI  infer_v_wf wfX_wfY * by metis
    show  \<open>atom z2 \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>\<close> using  fresh_replace_inside[of \<Theta> \<B> \<Gamma>' x b0 c0' \<Gamma> c0 ] infer_e_splitI  infer_v_wf wfX_wfY * by metis
    show  \<open>atom z3 \<sharp> \<Gamma>' @ (x, b0, c0) #\<^sub>\<Gamma> \<Gamma>\<close> using  fresh_replace_inside[of \<Theta> \<B> \<Gamma>' x b0 c0' \<Gamma> c0 ] infer_e_splitI  infer_v_wf wfX_wfY * by metis
    show \<open>atom z1 \<sharp> AE_split v1 v2\<close> using infer_e_splitI by auto
    show \<open>atom z2 \<sharp> AE_split v1 v2\<close> using infer_e_splitI by auto
    show \<open>atom z3 \<sharp> AE_split v1 v2\<close> using infer_e_splitI by auto
 qed
qed

lemma ctx_subtype_e_rig_eq:
  assumes "replace_in_g_subtyped \<Theta> \<B> \<Gamma>' [(x,c0)] \<Gamma>" and  
          "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>' ; \<Delta> \<turnstile> e \<Rightarrow> t1" 
        shows "\<Theta> ; \<Phi> ; \<B> ; \<Gamma> ; \<Delta> \<turnstile> e \<Rightarrow> t1"
proof - 
  obtain b and c0' and G and G' where "\<Gamma>' = G' @ (x,b,c0')#\<^sub>\<Gamma>G \<and>  \<Gamma> = G' @ (x,b,c0)#\<^sub>\<Gamma>G \<and>  \<Theta> ; \<B> ; G'@ (x,b,c0)#\<^sub>\<Gamma>G  \<Turnstile> c0'"
    using assms replace_in_g_inside_valid infer_e_wf by meson
  thus  ?thesis 
    using assms ctx_subtype_e_eq by presburger
qed


lemma ctx_subtype_e_rigs_eq:
  assumes "replace_in_g_subtyped \<Theta> \<B> \<Gamma>' xcs \<Gamma>" and  
          "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>'; \<Delta> \<turnstile> e \<Rightarrow> t1" 
        shows "\<Theta> ; \<Phi> ; \<B> ; \<Gamma> ; \<Delta> \<turnstile> e \<Rightarrow> t1"
using assms proof(induct xcs arbitrary: \<Gamma> \<Gamma>' t1 )
  case Nil
  moreover have "\<Gamma>' = \<Gamma>" using replace_in_g_subtyped_nilI 
    using calculation(1) by blast
  moreover have "\<Theta>;\<B>;\<Gamma> \<turnstile> t1 \<lesssim> t1" using subtype_reflI2 Nil infer_e_t_wf by blast
  ultimately show ?case by blast
next
  case (Cons a xcs)

  then obtain x and c where "a=(x,c)" by fastforce
  then obtain b and c' where bc: "Some (b, c') = lookup \<Gamma>' x \<and>
         replace_in_g_subtyped \<Theta> \<B> (replace_in_g \<Gamma>' x c) xcs \<Gamma> \<and> \<Theta> ; \<B> ; \<Gamma>'  \<turnstile>\<^sub>w\<^sub>f c \<and>
         x \<notin> fst ` set xcs \<and>   \<Theta> ; \<B> ; (replace_in_g \<Gamma>' x c)  \<Turnstile> c' " using replace_in_g_subtyped_elims(3)[of  \<Theta> \<B> \<Gamma>' x c xcs \<Gamma>] Cons
    by (metis valid.simps)

  hence *: "replace_in_g_subtyped \<Theta> \<B> \<Gamma>' [(x,c)] (replace_in_g \<Gamma>' x c)" using replace_in_g_subtyped_consI 
    by (meson image_iff list.distinct(1) list.set_cases replace_in_g_subtyped_nilI)
  hence   t2: "\<Theta> ; \<Phi> ; \<B> ; (replace_in_g \<Gamma>' x c) ; \<Delta> \<turnstile> e \<Rightarrow> t1 " using ctx_subtype_e_rig_eq[OF * Cons(3)] by blast
  moreover have **: "replace_in_g_subtyped  \<Theta> \<B> (replace_in_g \<Gamma>' x c) xcs \<Gamma>" using bc by auto
  ultimately have  t2': "\<Theta> ; \<Phi> ; \<B> ; \<Gamma> ; \<Delta> \<turnstile> e \<Rightarrow> t1" using Cons by blast
  thus  ?case  by blast
qed

section \<open>Statements\<close>



lemma ctx_subtype_s_rigs:
  fixes c0::c and s::s and G'::\<Gamma> and xcs :: "(x*c) list" and css::branch_list
  shows
          "check_s \<Theta> \<Phi> \<B> G \<Delta>  s  t1 \<Longrightarrow> wsX G xcs  \<Longrightarrow> replace_in_g_subtyped \<Theta> \<B> G xcs G'  \<Longrightarrow> check_s \<Theta> \<Phi> \<B> G' \<Delta>  s  t1" and 
          "check_branch_s \<Theta> \<Phi> \<B> G \<Delta> tid cons const v cs  t1 \<Longrightarrow>  wsX G xcs  \<Longrightarrow> replace_in_g_subtyped  \<Theta> \<B> G xcs G'  \<Longrightarrow> check_branch_s \<Theta> \<Phi> \<B> G' \<Delta> tid cons const v cs t1"
          "check_branch_list \<Theta> \<Phi> \<B> G \<Delta> tid dclist v css  t1 \<Longrightarrow>  wsX G xcs  \<Longrightarrow> replace_in_g_subtyped  \<Theta> \<B> G xcs G'  \<Longrightarrow> check_branch_list \<Theta> \<Phi> \<B> G' \<Delta> tid dclist v css t1"
proof(induction   arbitrary:  xcs G' and xcs G' and xcs G' rule: check_s_check_branch_s_check_branch_list.inducts)
  case (check_valI \<Theta> \<B> \<Gamma> \<Delta> \<Phi> v \<tau>' \<tau>)
  hence *:"\<Theta> ; \<B> ; G'  \<turnstile> v \<Rightarrow> \<tau>' \<and>  \<Theta> ; \<B> ; G'  \<turnstile> \<tau>' \<lesssim> \<tau>" using ctx_subtype_v_rigs_eq ctx_subtype_subtype_rigs 
    by (meson check_v.simps)
  show ?case proof
     show \<open>\<Theta> ; \<B> ; G' \<turnstile>\<^sub>w\<^sub>f \<Delta>\<close> using check_valI wfD_rig by auto
     show \<open>\<Theta> \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using check_valI by auto
     show \<open>\<Theta> ; \<B> ; G'  \<turnstile> v \<Rightarrow> \<tau>'\<close> using * by auto
     show \<open>\<Theta> ; \<B> ; G'  \<turnstile> \<tau>' \<lesssim> \<tau>\<close> using * by auto
   qed
 next
   case (check_letI x \<Theta> \<Phi> \<B> \<Gamma> \<Delta> e \<tau> z' s b' c')
   thm replace_in_g_wfG
  show ?case proof
    have wfG: "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f \<Gamma> \<and> \<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f G'" using infer_e_wf check_letI replace_in_g_wfG   using infer_e_wf(2) by (auto simp add: freshers)
    hence "atom x \<sharp> G'" using check_letI replace_in_g_fresh replace_in_g_wfG  by auto
    thus  "atom x \<sharp> (\<Theta>, \<Phi>, \<B>, G', \<Delta>, e, \<tau>)" using check_letI by auto
    have "atom z' \<sharp> G'" apply(rule replace_in_g_fresh[OF check_letI(7)]) 
      using replace_in_g_wfG check_letI fresh_prodN infer_e_wf by metis+
    thus "atom z' \<sharp> (x, \<Theta>, \<Phi>, \<B>, G', \<Delta>, e, \<tau>, s)" using check_letI fresh_prodN by metis
  
    show "\<Theta> ; \<Phi> ; \<B> ; G' ; \<Delta>  \<turnstile> e \<Rightarrow> \<lbrace> z' : b'  | c' \<rbrace>" 
      using check_letI ctx_subtype_e_rigs_eq by blast 
    show "\<Theta> ; \<Phi> ; \<B> ; (x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> G' ; \<Delta>  \<turnstile> s \<Leftarrow> \<tau>" 
    proof(rule  check_letI(5))
      have vld: "\<Theta>;\<B>;((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) \<Turnstile>  c'[z'::=V_var x]\<^sub>c\<^sub>v" proof -
        have "wfG \<Theta> \<B> ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" using check_letI check_s_wf  by metis
        hence "wfC \<Theta> \<B> ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) (c'[z'::=V_var x]\<^sub>c\<^sub>v)" using wfC_refl subst_defs by auto
        thus ?thesis using  valid_reflI[of  \<Theta> \<B> x b' "c'[z'::=V_var x]\<^sub>v" \<Gamma> " c'[z'::=V_var x]\<^sub>v"] subst_defs by auto
      qed
      have xf: "x \<notin> fst ` set xcs" proof -
        have  "atom ` fst ` set xcs \<subseteq> atom_dom \<Gamma>" using check_letI wsX_iff by meson 
        moreover have "wfG \<Theta> \<B> \<Gamma>" using infer_e_wf check_letI by metis
        ultimately show ?thesis using fresh_def  check_letI  wfG_dom_supp 
          using wsX_fresh by auto
      qed
      show "replace_in_g_subtyped \<Theta> \<B> ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) ((x, c'[z'::=V_var x]\<^sub>v) # xcs) ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> G')" proof -

        have "Some (b', c'[z'::=V_var x]\<^sub>v) =  lookup ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) x" by auto

        moreover have "\<Theta> ; \<B> ; replace_in_g ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) x  (c'[z'::=V_var x]\<^sub>v) \<Turnstile>  c'[z'::=V_var x]\<^sub>v" proof -
          have "replace_in_g ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) x  (c'[z'::=V_var x]\<^sub>v) = ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" 
            using replace_in_g.simps by presburger
          thus ?thesis  using vld subst_defs by auto
        qed
     
        moreover have " replace_in_g_subtyped \<Theta> \<B> (replace_in_g ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) x (c'[z'::=V_var x]\<^sub>v)) xcs ( ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> G'))" proof -
          have "wfG \<Theta> \<B> ( ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>))"  using check_letI check_s_wf  by metis
          hence "replace_in_g_subtyped \<Theta> \<B> ( ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)) xcs ( ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> G'))" 
            using check_letI replace_in_g_subtyped_cons xf by meson
          moreover have "replace_in_g ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) x (c'[z'::=V_var x]\<^sub>v) = ( ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>))"
            using replace_in_g.simps by presburger
          ultimately show ?thesis by argo
        qed      
        moreover  have "\<Theta> ; \<B> ; (x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f  c'[z'::=V_var x]\<^sub>v " using vld subst_defs by auto
        ultimately show ?thesis using  replace_in_g_subtyped_consI xf replace_in_g.simps(2) by metis
      qed

      show " wsX ((x, b', c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) ((x, c'[z'::=V_var x]\<^sub>v) # xcs)" 
        using check_letI xf subst_defs  by (simp add: wsX_cons)  
    qed
  qed

next
  case (check_branch_list_consI \<Theta> \<Phi> \<B> \<Gamma> \<Delta> tid dclist v cs \<tau> css)
  then show ?case using Typing.check_branch_list_consI by auto
next
  case (check_branch_list_finalI \<Theta> \<Phi> \<B> \<Gamma> \<Delta> tid dclist v cs \<tau>)
  then show ?case using Typing.check_branch_list_finalI by auto
next
   case (check_branch_s_branchI \<Theta> \<B> \<Gamma> \<Delta> \<tau> const x \<Phi> tid cons v s)

  have wfcons: "wfG \<Theta> \<B> ((x, b_of const, CE_val v  ==  CE_val (V_cons tid cons (V_var x))  AND c_of const x) #\<^sub>\<Gamma> \<Gamma>)" using check_s_wf check_branch_s_branchI
    by meson
  hence wf: "wfG \<Theta> \<B> \<Gamma>" using  wfG_cons by metis

  moreover have "atom x \<sharp> (const, G',v)"  proof -
    have "atom x \<sharp> G'"  using check_branch_s_branchI wf replace_in_g_fresh 
       wfG_dom_supp replace_in_g_wfG by simp
    thus ?thesis using check_branch_s_branchI fresh_prodN by simp
  qed

  moreover have st: "\<Theta> ; \<Phi> ; \<B> ; (x, b_of const, CE_val v  ==  CE_val(V_cons tid cons (V_var x))  AND  c_of const x) #\<^sub>\<Gamma> G' ; \<Delta>  \<turnstile> s \<Leftarrow> \<tau> " proof -
    have " wsX ((x, b_of const, CE_val v  ==  CE_val(V_cons tid cons (V_var x))   AND c_of const x) #\<^sub>\<Gamma> \<Gamma>) xcs" using check_branch_s_branchI wsX_cons2 wsX_fresh wf by force
    moreover have "replace_in_g_subtyped \<Theta> \<B> ((x,  b_of const, CE_val v  ==  CE_val (V_cons tid cons (V_var x))   AND  c_of const x) #\<^sub>\<Gamma> \<Gamma>) xcs ((x,  b_of const, CE_val v  ==  CE_val(V_cons tid cons (V_var x)) AND  c_of const x) #\<^sub>\<Gamma> G' )" 
      using replace_in_g_subtyped_cons wsX_fresh wf check_branch_s_branchI wfcons by auto
    thus ?thesis using check_branch_s_branchI  calculation by meson
  qed
 moreover have wft: " wfT \<Theta> \<B> G' \<tau> " using
     check_branch_s_branchI ctx_subtype_subtype_rigs subtype_reflI2 subtype_wf by metis
  moreover have "wfD \<Theta> \<B> G' \<Delta>" using check_branch_s_branchI wfD_rig by presburger
  ultimately show ?case using 
    Typing.check_branch_s_branchI 
    using check_branch_s_branchI.hyps by simp

next
   case (check_ifI z \<Theta> \<Phi> \<B> \<Gamma> \<Delta> v s1 s2 \<tau>)
   hence wf:"wfG \<Theta> \<B> \<Gamma>" using check_s_wf by presburger
   show ?case proof(rule check_s_check_branch_s_check_branch_list.check_ifI)
     show \<open>atom z \<sharp> (\<Theta>, \<Phi>, \<B>, G', \<Delta>, v, s1, s2, \<tau>)\<close> using fresh_prodN replace_in_g_fresh1 wf check_ifI by auto
     show \<open>\<Theta> ; \<B> ; G'  \<turnstile> v \<Leftarrow> \<lbrace> z : B_bool  | TRUE \<rbrace>\<close> using ctx_subtype_check_v_rigs_eq check_ifI by presburger
     show \<open> \<Theta> ; \<Phi> ; \<B> ; G' ; \<Delta>  \<turnstile> s1 \<Leftarrow> \<lbrace> z : b_of \<tau>  | CE_val v  ==  CE_val (V_lit L_true)   IMP  c_of \<tau> z  \<rbrace>\<close> using  check_ifI by auto
     show \<open> \<Theta> ; \<Phi> ; \<B> ; G' ; \<Delta>  \<turnstile> s2 \<Leftarrow> \<lbrace> z : b_of \<tau>  | CE_val v  ==  CE_val (V_lit L_false)   IMP  c_of \<tau> z  \<rbrace>\<close> using  check_ifI by auto
   qed
 next

 case (check_let2I x P \<Phi> \<B> G \<Delta> t s1 \<tau> s2 )
  show ?case proof
    have "wfG P \<B> G" using check_let2I check_s_wf by metis
    show  *: "P ; \<Phi> ; \<B> ; G' ; \<Delta>  \<turnstile> s1 \<Leftarrow>t" using check_let2I by blast
    show  "atom x \<sharp> (P, \<Phi>, \<B>, G', \<Delta>, t, s1, \<tau>)" proof -
      have "wfG P \<B> G'" using check_s_wf * by blast
      hence "atom_dom G = atom_dom G'" using check_let2I rigs_atom_dom_eq by presburger
      moreover have "atom x \<sharp> G" using check_let2I by auto
      moreover have "wfG P \<B> G" using check_s_wf *  replace_in_g_wfG  check_let2I by simp
      ultimately have "atom x \<sharp> G'" using wfG_dom_supp fresh_def \<open>wfG P \<B> G'\<close> by metis
      thus ?thesis using check_let2I by auto
    qed
    show "P ; \<Phi> ; \<B> ;(x, b_of t, c_of t x) #\<^sub>\<Gamma> G' ; \<Delta>  \<turnstile> s2 \<Leftarrow> \<tau> " proof - 
      have "wsX ((x, b_of t, c_of t x) #\<^sub>\<Gamma> G) xcs" using check_let2I wsX_cons2  wsX_fresh \<open>wfG P \<B> G\<close> by simp
      moreover have "replace_in_g_subtyped P \<B> ((x,  b_of t, c_of t x) #\<^sub>\<Gamma> G) xcs ((x,  b_of t, c_of t x) #\<^sub>\<Gamma> G')" proof(rule  replace_in_g_subtyped_cons )
        show "replace_in_g_subtyped P \<B> G xcs G'" using check_let2I by auto
        have "atom x \<sharp> G" using check_let2I by auto
        moreover have "wfT P \<B> G t" using check_let2I check_s_wf by metis
    
        moreover have "atom x \<sharp> t" using check_let2I check_s_wf wfT_supp by auto
        ultimately show "wfG P \<B> ((x,  b_of t, c_of t x) #\<^sub>\<Gamma> G)" using wfT_wf_cons b_of_c_of_eq[of x t] by auto
        show "x \<notin> fst ` set xcs" using check_let2I wsX_fresh \<open>wfG P \<B> G\<close> by simp
      qed
      ultimately show ?thesis using check_let2I by presburger
    qed  
  qed
next
  case (check_varI u \<Theta> \<Phi> \<B> \<Gamma> \<Delta> \<tau>' v \<tau> s)
  show ?case proof
    have "atom u \<sharp> G'" unfolding fresh_def
      apply(rule  u_not_in_g , rule replace_in_g_wfG)
      using check_v_wf check_varI by simp+
    thus  \<open>atom u \<sharp> (\<Theta>, \<Phi>, \<B>, G', \<Delta>, \<tau>', v, \<tau>)\<close> unfolding fresh_prodN using check_varI by simp
    show \<open>\<Theta> ; \<B> ; G'  \<turnstile> v \<Leftarrow> \<tau>'\<close> using ctx_subtype_check_v_rigs_eq check_varI by auto
    show \<open> \<Theta> ; \<Phi> ; \<B> ; G' ; (u, \<tau>') #\<^sub>\<Delta> \<Delta>  \<turnstile> s \<Leftarrow> \<tau>\<close> using  check_varI by auto
  qed
next
  case (check_assignI P \<Phi> \<B> G \<Delta> u \<tau> v z \<tau>')
  show ?case proof
    show \<open>P  \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using  check_assignI by auto
    show \<open>P ; \<B> ; G'  \<turnstile>\<^sub>w\<^sub>f \<Delta> \<close>  using  check_assignI wfD_rig by auto
    show \<open>(u, \<tau>) \<in> setD \<Delta>\<close>  using  check_assignI by auto
    show \<open>P ; \<B> ; G'  \<turnstile> v \<Leftarrow> \<tau>\<close> using ctx_subtype_check_v_rigs_eq check_assignI by auto
    show \<open>P ; \<B> ; G'  \<turnstile> \<lbrace> z : B_unit  | TRUE \<rbrace> \<lesssim> \<tau>'\<close>  using ctx_subtype_subtype_rigs check_assignI by auto
  qed
next
  case (check_whileI \<Delta> G P s1 z s2 \<tau>')
  then show ?case using Typing.check_whileI
    by (meson ctx_subtype_subtype_rigs)
next
  case (check_seqI \<Delta> G P s1 z s2 \<tau>)
  then show ?case 
    using check_s_check_branch_s_check_branch_list.check_seqI by blast
next
  case (check_caseI \<Theta> \<Phi> \<B> \<Gamma> \<Delta> tid dclist v cs \<tau> z)
  show ?case proof
    show " \<Theta> ;  \<Phi> ; \<B> ; G' ; \<Delta> ; tid ; dclist ; v \<turnstile> cs \<Leftarrow> \<tau>" using check_caseI ctx_subtype_check_v_rigs_eq by auto
    show "AF_typedef tid dclist \<in> set  \<Theta>" using check_caseI by auto
    show "\<Theta> ; \<B> ; G'  \<turnstile> v \<Leftarrow> \<lbrace> z : B_id tid  | TRUE \<rbrace>" using check_caseI ctx_subtype_check_v_rigs_eq by auto
    show "\<turnstile>\<^sub>w\<^sub>f \<Theta> " using check_caseI by auto
  qed
next
  case (check_assertI x \<Theta> \<Phi> \<B> \<Gamma> \<Delta> c \<tau> s)
  show ?case proof
    have wfG: "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f \<Gamma> \<and> \<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f G'" using check_s_wf check_assertI replace_in_g_wfG wfX_wfY by metis
    hence "atom x \<sharp> G'" using check_assertI replace_in_g_fresh replace_in_g_wfG  by auto
    thus  \<open>atom x \<sharp> (\<Theta>, \<Phi>, \<B>, G', \<Delta>, c, \<tau>, s)\<close> using check_assertI fresh_prodN by auto
    show \<open> \<Theta> ; \<Phi> ; \<B> ; (x, B_bool, c) #\<^sub>\<Gamma> G' ; \<Delta>  \<turnstile> s \<Leftarrow> \<tau>\<close> proof(rule check_assertI(5) )
      show "wsX ((x, B_bool, c) #\<^sub>\<Gamma> \<Gamma>) xcs" using check_assertI wsX_cons3   by simp
      show "\<Theta> ; \<B>  \<turnstile> (x, B_bool, c) #\<^sub>\<Gamma> \<Gamma> \<langle> xcs \<rangle> \<leadsto> (x, B_bool, c) #\<^sub>\<Gamma> G'" proof(rule  replace_in_g_subtyped_cons)
        show \<open> \<Theta> ; \<B>  \<turnstile> \<Gamma> \<langle> xcs \<rangle> \<leadsto> G'\<close> using check_assertI by auto
        show \<open> \<Theta> ; \<B>  \<turnstile>\<^sub>w\<^sub>f (x, B_bool, c) #\<^sub>\<Gamma> \<Gamma> \<close> using check_assertI check_s_wf by metis
        thus \<open>x \<notin> fst ` set xcs\<close> using check_assertI wsX_fresh wfG_elims wfX_wfY by metis
      qed
    qed
    show \<open>\<Theta> ; \<B> ; G'  \<Turnstile> c \<close> using check_assertI replace_in_g_valid by auto
    show \<open> \<Theta> ; \<B> ; G' \<turnstile>\<^sub>w\<^sub>f \<Delta> \<close> using check_assertI wfD_rig by auto
  qed
qed



lemma replace_in_g_subtyped_empty:
  assumes "wfG \<Theta> \<B> (\<Gamma>' @ (x, b, c[z::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" 
  shows  "replace_in_g_subtyped \<Theta> \<B> (replace_in_g (\<Gamma>' @ (x, b, c[z::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) x (c'[z'::=V_var x]\<^sub>c\<^sub>v)) [] (\<Gamma>' @ (x, b, c'[z'::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)"
proof -
  have "replace_in_g (\<Gamma>' @ (x, b, c[z::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) x (c'[z'::=V_var x]\<^sub>c\<^sub>v) = (\<Gamma>' @ (x, b, c'[z'::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" 
  using assms proof(induct \<Gamma>' rule: \<Gamma>_induct)
    case GNil
    then show ?case using replace_in_g.simps by auto
  next
    case (GCons x1 b1 c1 \<Gamma>1)
    have "x \<notin> fst ` setG ((x1,b1,c1)#\<^sub>\<Gamma>\<Gamma>1)"  using GCons wfG_inside_fresh atom_dom.simps setG.simps append_g.simps by fast
    hence "x1 \<noteq> x" using assms wfG_inside_fresh GCons by force
    hence "((x1,b1,c1) #\<^sub>\<Gamma> (\<Gamma>1 @ (x, b, c[z::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>))[x\<longmapsto>c'[z'::=V_var x]\<^sub>c\<^sub>v] = (x1,b1,c1) #\<^sub>\<Gamma> (\<Gamma>1 @ (x, b, c'[z'::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)"
      using replace_in_g.simps GCons wfG_elims append_g.simps by metis
    thus ?case using append_g.simps by simp
  qed
  thus ?thesis using replace_in_g_subtyped_nilI by presburger
qed

lemma ctx_subtype_s:
  fixes  s::s
  assumes "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>'@((x,b,c[z::=V_var x]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>) ; \<Delta> \<turnstile> s \<Leftarrow> \<tau>" and 
          "\<Theta> ; \<B> ; \<Gamma> \<turnstile> \<lbrace> z' : b | c' \<rbrace> \<lesssim> \<lbrace> z : b | c \<rbrace>" and 
          "atom x \<sharp> (z,z',c,c')"
  shows "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>'@(x,b,c'[z'::=V_var x]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma> ; \<Delta> \<turnstile> s \<Leftarrow> \<tau>"
proof - 
 
  have wf: "wfG \<Theta> \<B> (\<Gamma>'@((x,b,c[z::=V_var x]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>))" using check_s_wf assms by meson
  hence *:"x \<notin> fst ` setG \<Gamma>'" using wfG_inside_fresh by force
  have "wfG \<Theta> \<B> ((x,b,c[z::=V_var x]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>)" using wf wfG_suffix by metis
  hence xfg: "atom x \<sharp> \<Gamma>" using wfG_elims by metis
  have "x \<noteq> z'"  using assms fresh_at_base fresh_prod4 by metis
  hence  a2: "atom x \<sharp> c'" using assms fresh_prod4 by metis

  have "atom x \<sharp> (z', c', z, c, \<Gamma>)" proof -       
    have "x \<noteq> z" using assms  using assms fresh_at_base fresh_prod4 by metis
    hence  a1 : "atom x \<sharp> c" using assms subtype_wf   subtype_wf assms wfT_fresh_c xfg by meson
    thus ?thesis using a1 a2 \<open>atom x \<sharp> (z,z',c,c')\<close> fresh_prod4 fresh_Pair xfg by simp
  qed
  hence wc1:" \<Theta> ; \<B> ; (x, b, c'[z'::=V_var x]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<Turnstile> c[z::=V_var x]\<^sub>v"
    using  subtype_valid assms fresh_prodN by metis  

  have vld: "\<Theta>;\<B> ; (\<Gamma>'@(x, b, c'[z'::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) \<Turnstile> c[z::=V_var x]\<^sub>c\<^sub>v" proof - 

      have "setG ((x, b, c'[z'::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) \<subseteq> setG (\<Gamma>'@(x, b, c'[z'::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" by auto
      moreover have "wfG \<Theta> \<B> (\<Gamma>'@(x, b, c'[z'::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" proof -
        have *:"wfT \<Theta> \<B> \<Gamma> (\<lbrace> z' : b | c' \<rbrace>)" using subtype_wf assms by meson
        moreover have "atom x \<sharp> (c',\<Gamma>)" using xfg a2 by simp
        ultimately have "wfG \<Theta> \<B> ((x, b, c'[z'::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" using wfT_wf_cons_flip  freshers by blast
        thus ?thesis using wfG_replace_inside2 check_s_wf assms  by metis
      qed
      ultimately show ?thesis using wc1 valid_weakening subst_defs by metis
  qed
  hence  wbc: "\<Theta> ; \<B> ; \<Gamma>' @ (x, b, c'[z'::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f c[z::=V_var x]\<^sub>c\<^sub>v" using valid.simps by auto
  have wbc1: "\<Theta> ; \<B> ; (x, b, c'[z'::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f c[z::=V_var x]\<^sub>c\<^sub>v" using wc1 valid.simps subst_defs by auto
  have "wsX  (\<Gamma>'@((x,b,c[z::=V_var x]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>)) [(x, c'[z'::=V_var x]\<^sub>c\<^sub>v)]" proof 
    show " wsX (\<Gamma>' @ (x, b, c[z::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) []" using wsX_NilI by auto
    show "atom x \<in> atom_dom (\<Gamma>' @ (x, b, c[z::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" by simp
    show "x \<notin> fst ` set []" by auto
  qed
  moreover have "replace_in_g_subtyped \<Theta> \<B> (\<Gamma>'@((x,b,c[z::=V_var x]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>)) [(x, c'[z'::=V_var x]\<^sub>c\<^sub>v)] (\<Gamma>'@(x,b,c'[z'::=V_var x]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>)" proof
    show "Some (b, c[z::=V_var x]\<^sub>c\<^sub>v) = lookup (\<Gamma>' @ (x, b, c[z::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) x" using lookup_inside* by auto
    show " \<Theta> ; \<B> ; replace_in_g (\<Gamma>' @ (x, b, c[z::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) x (c'[z'::=V_var x]\<^sub>c\<^sub>v)  \<Turnstile> c[z::=V_var x]\<^sub>c\<^sub>v"  using vld replace_in_g_split wf by metis
    show "replace_in_g_subtyped \<Theta> \<B> (replace_in_g (\<Gamma>' @ (x, b, c[z::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) x (c'[z'::=V_var x]\<^sub>c\<^sub>v)) [] (\<Gamma>' @ (x, b, c'[z'::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" 
      using replace_in_g_subtyped_empty wf by presburger
    show "x \<notin> fst ` set []" by auto
    show "\<Theta> ; \<B> ; \<Gamma>' @ (x, b, c[z::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f c'[z'::=V_var x]\<^sub>c\<^sub>v" 
    proof(rule wf_weakening)
     show \<open> \<Theta> ; \<B> ; (x, b, c[z::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f c'[z'::=[ x ]\<^sup>v]\<^sub>c\<^sub>v \<close>   using wfC_cons_switch[OF wbc1] wf_weakening(6) check_s_wf assms setG.simps  by metis 
     show \<open> \<Theta> ; \<B>  \<turnstile>\<^sub>w\<^sub>f \<Gamma>' @ (x, b, c[z::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma> \<close>   using wfC_cons_switch[OF wbc1] wf_weakening(6) check_s_wf assms setG.simps  by metis
     show \<open>setG ((x, b, c[z::=V_var x]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) \<subseteq> setG (\<Gamma>' @ (x, b, c[z::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)\<close> using append_g.simps setG.simps by auto
   qed    
  qed
  ultimately show ?thesis using ctx_subtype_s_rigs(1)[OF assms(1)] by presburger 
qed

end