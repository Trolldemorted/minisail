(*<*)
theory IVSubstTypingL
  imports  "HOL-Eisbach.Eisbach_Tools" Explorer ContextSubtypingL
begin
(*>*)

chapter \<open>Immutable Variable Substitution Lemmas\<close>
text \<open> Lemmas that show that types are preserved, in some way, under immutable variable substitution\<close>

section \<open>Misc\<close>
(* MOVE *)

lemma subst_top_eq:
   "\<lbrace> z : b  | TRUE \<rbrace> = \<lbrace> z : b  | TRUE \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v" 
proof -
  obtain z'::x and c' where zeq: "\<lbrace> z : b  | TRUE \<rbrace> = \<lbrace> z' : b | c' \<rbrace> \<and> atom z' \<sharp> (x,v)" using obtain_fresh_z2 b_of.simps by metis
  hence "\<lbrace> z' : b  | TRUE \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v =  \<lbrace> z' : b | TRUE \<rbrace>" using subst_tv.simps subst_cv.simps by metis
  moreover have "c' = C_true" using \<tau>.eq_iff Abs1_eq_iff(3) c.fresh flip_fresh_fresh  by (metis zeq) 
  ultimately show ?thesis using zeq by metis
qed


lemma wfD_subst:
  fixes \<tau>\<^sub>1::\<tau> and v::v and \<Delta>::\<Delta> and \<Theta>::\<Theta> and \<Gamma>::\<Gamma>
  assumes "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<tau>\<^sub>1" and "wfD \<Theta>  \<B> (\<Gamma>'@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>))  \<Delta>" and "b_of \<tau>\<^sub>1=b\<^sub>1"
  shows " \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v"
proof -
  have "\<Theta> ; \<B> ; \<Gamma>\<turnstile>\<^sub>w\<^sub>f v : b\<^sub>1" using infer_v_v_wf assms by auto
  moreover have  "(\<Gamma>'@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>))[x::=v]\<^sub>\<Gamma>\<^sub>v = \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>"  using subst_g_inside wfD_wf  assms by metis
  ultimately show ?thesis  using  wf_subst assms by metis
qed

lemma subst_v_c_of:
  assumes  "atom xa \<sharp> (v,x)"
  shows  "c_of t[x::=v]\<^sub>\<tau>\<^sub>v xa = (c_of t xa)[x::=v]\<^sub>c\<^sub>v" 
using assms proof(nominal_induct t avoiding: x v xa rule:\<tau>.strong_induct)
  case (T_refined_type z' b' c')
  then have " c_of \<lbrace> z' : b'  | c' \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v xa  = c_of \<lbrace> z' : b'  | c'[x::=v]\<^sub>c\<^sub>v \<rbrace> xa" 
    using subst_tv.simps fresh_Pair by metis
  also have "... =  c'[x::=v]\<^sub>c\<^sub>v [z'::=V_var xa]\<^sub>c\<^sub>v" using c_of.simps T_refined_type by metis
  also have "... = c' [z'::=V_var xa]\<^sub>c\<^sub>v[x::=v]\<^sub>c\<^sub>v" 
    using subst_cv_commute_subst[of z' v x "V_var xa" c'] subst_v_c_def T_refined_type fresh_Pair fresh_at_base v.fresh fresh_x_neq by metis
  finally show ?case using c_of.simps T_refined_type by metis  
qed

section \<open>Context\<close>

lemma subst_lookup:
  assumes "Some (b,c) = lookup (\<Gamma>'@((x,b\<^sub>1,c\<^sub>1)#\<^sub>\<Gamma>\<Gamma>)) y" and "x \<noteq> y" and "wfG \<Theta> \<B> (\<Gamma>'@((x,b\<^sub>1,c\<^sub>1)#\<^sub>\<Gamma>\<Gamma>))"
  shows "\<exists>d. Some (b,d) = lookup ((\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v)@\<Gamma>) y" 
using assms proof(induct \<Gamma>' rule: \<Gamma>_induct)
  case GNil
  hence "Some (b,c) = lookup \<Gamma> y"     by (simp add: assms(1))
  then show ?case using subst_gv.simps by auto
next
  case (GCons x1 b1 c1  \<Gamma>1)
  show ?case proof(cases "x1 = x")
    case True
    hence "atom x \<sharp> (\<Gamma>1 @ (x, b\<^sub>1, c\<^sub>1) #\<^sub>\<Gamma> \<Gamma>)" using GCons wfG_elims(2)
       append_g.simps  by metis
    moreover have  "atom x \<in> atom_dom (\<Gamma>1 @ (x, b\<^sub>1, c\<^sub>1) #\<^sub>\<Gamma> \<Gamma>)" by simp
    ultimately show ?thesis 
      using forget_subst_gv  not_GCons_self2 subst_gv.simps append_g.simps  
      by (metis GCons.prems(3) True wfG_cons_fresh2 )
  next
    case False
    hence "((x1,b1,c1) #\<^sub>\<Gamma> \<Gamma>1)[x::=v]\<^sub>\<Gamma>\<^sub>v = (x1,b1,c1[x::=v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>1[x::=v]\<^sub>\<Gamma>\<^sub>v"  using subst_gv.simps by auto
    then show ?thesis  proof(cases "x1=y")
    case True
      then show ?thesis using GCons  using lookup.simps 
      by (metis \<open>((x1, b1, c1) #\<^sub>\<Gamma> \<Gamma>1)[x::=v]\<^sub>\<Gamma>\<^sub>v = (x1, b1, c1[x::=v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>1[x::=v]\<^sub>\<Gamma>\<^sub>v\<close> append_g.simps fst_conv option.inject)
     next
       case False
       then show ?thesis using GCons  using lookup.simps 
        using \<open>((x1, b1, c1) #\<^sub>\<Gamma> \<Gamma>1)[x::=v]\<^sub>\<Gamma>\<^sub>v = (x1, b1, c1[x::=v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>1[x::=v]\<^sub>\<Gamma>\<^sub>v\<close> append_g.simps \<Gamma>.distinct \<Gamma>.inject wfG.simps wfG_elims by metis
        
    qed
  qed
qed

section \<open>Satisfiability\<close>

lemma is_satis_g_i_upd2:
  assumes "eval_v i v s" and "is_satis ((i ( x \<mapsto> s))) c0" and "atom x \<sharp> G" and "wfG \<Theta> \<B> (G3@((x,b,c0)#\<^sub>\<Gamma>G))" and "wfV \<Theta> \<B> G v b" and "wfI \<Theta> (G3[x::=v]\<^sub>\<Gamma>\<^sub>v@G) i" 
  and  "is_satis_g i (G3[x::=v]\<^sub>\<Gamma>\<^sub>v@G)"
  shows "is_satis_g (i ( x \<mapsto> s)) (G3@((x,b,c0)#\<^sub>\<Gamma>G))"
using assms proof(induct G3 rule: \<Gamma>_induct)
  case GNil
  hence "is_satis_g (i(x \<mapsto> s)) G" using is_satis_g_i_upd by auto
  then show ?case using GNil using is_satis_g.simps append_g.simps by metis
next
  case (GCons x' b' c' \<Gamma>')
  hence "x\<noteq>x'" using wfG_cons_append  by metis
  hence "is_satis_g i (((x', b', c'[x::=v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v) @ G))" using subst_gv.simps GCons by auto
  hence *:"is_satis i c'[x::=v]\<^sub>c\<^sub>v \<and> is_satis_g i ((\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v) @ G)" using subst_gv.simps by auto

  have "is_satis_g (i(x \<mapsto> s)) ((x', b', c') #\<^sub>\<Gamma> (\<Gamma>'@  (x, b, c0) #\<^sub>\<Gamma> G))" proof(subst is_satis_g.simps,rule)
    show "is_satis (i(x \<mapsto> s)) c'" proof(subst subst_c_satis_full[symmetric])
      show \<open>eval_v i v s\<close> using GCons by auto
      show \<open> \<Theta> ; \<B> ; ((x', b', c') #\<^sub>\<Gamma>\<Gamma>')@(x, b, c0) #\<^sub>\<Gamma> G \<turnstile>\<^sub>w\<^sub>f c' \<close> using GCons wfC_refl by auto
      show \<open>wfI \<Theta> ((((x', b', c') #\<^sub>\<Gamma> \<Gamma>')[x::=v]\<^sub>\<Gamma>\<^sub>v) @ G) i\<close> using GCons  by auto
      show \<open> \<Theta> ; \<B> ; G \<turnstile>\<^sub>w\<^sub>f v : b \<close> using GCons by auto
      show \<open>is_satis i c'[x::=v]\<^sub>c\<^sub>v\<close> using * by auto
    qed
    show "is_satis_g (i(x \<mapsto> s)) (\<Gamma>' @ (x, b, c0) #\<^sub>\<Gamma> G)" proof(rule  GCons(1))
      show \<open>eval_v i v s\<close> using GCons by auto
      show \<open>is_satis (i(x \<mapsto> s)) c0\<close> using GCons by metis
      show \<open>atom x \<sharp> G\<close> using GCons by auto
      show \<open> \<Theta> ; \<B>\<turnstile>\<^sub>w\<^sub>f \<Gamma>' @ (x, b, c0) #\<^sub>\<Gamma> G \<close> using GCons wfG_elims append_g.simps by metis
      show \<open>is_satis_g i (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ G)\<close> using * by auto
      show "wfI \<Theta> (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ G) i" using GCons wfI_def subst_g_assoc_cons \<open>x\<noteq>x'\<close> by auto
      show "\<Theta> ; \<B> ; G \<turnstile>\<^sub>w\<^sub>f v : b "  using GCons by auto
    qed
  qed
  moreover have "((x', b', c') #\<^sub>\<Gamma> \<Gamma>' @ (x, b, c0) #\<^sub>\<Gamma> G) = (((x', b', c') #\<^sub>\<Gamma> \<Gamma>') @ (x, b, c0) #\<^sub>\<Gamma> G)" by auto
  ultimately show ?case using GCons by metis
qed

lemma is_satis_eq:
  assumes "wfI \<Theta> G i" and "wfCE \<Theta> \<B> G e b"
  shows "is_satis i (e == e)"
proof(rule)
  obtain s where "eval_e i e s" using eval_e_exist assms by metis
  thus "eval_c i (e  ==  e ) True" using eval_c_eqI by metis
qed

section \<open>Validity\<close>

lemma subst_self_valid: 
 fixes v::v
 assumes  "\<Theta> ; \<B> ; G \<turnstile> v \<Rightarrow> \<lbrace> z : b | c \<rbrace>" and "atom z \<sharp> v"
 shows " \<Theta> ; \<B> ; G \<Turnstile> c[z::=v]\<^sub>c\<^sub>v"
proof - 
  have "c= (CE_val (V_var z)  ==  CE_val v )" using  infer_v_form2 assms by presburger
  hence "c[z::=v]\<^sub>c\<^sub>v = (CE_val (V_var z)  ==  CE_val v )[z::=v]\<^sub>c\<^sub>v" by auto
  also have "... = (((CE_val (V_var z))[z::=v]\<^sub>c\<^sub>e\<^sub>v) ==  ((CE_val v)[z::=v]\<^sub>c\<^sub>e\<^sub>v))" by fastforce
  also have "... = ((CE_val v) ==  ((CE_val v)[z::=v]\<^sub>c\<^sub>e\<^sub>v))" using subst_cev.simps subst_vv.simps by presburger
  also have "... = (CE_val v  ==  CE_val v )" using infer_v_form subst_cev.simps assms forget_subst_vv   by presburger
  finally have *:"c[z::=v]\<^sub>c\<^sub>v = (CE_val v  ==  CE_val v )" by auto

  have **:"\<Theta> ; \<B> ; G\<turnstile>\<^sub>w\<^sub>f CE_val v : b" using wfCE_valI  assms infer_v_v_wf b_of.simps by metis

  show ?thesis proof(rule validI)
    show  "\<Theta> ; \<B> ; G\<turnstile>\<^sub>w\<^sub>f c[z::=v]\<^sub>c\<^sub>v" proof -
      have "\<Theta> ; \<B> ; G\<turnstile>\<^sub>w\<^sub>f v : b" using infer_v_v_wf assms b_of.simps by metis
      moreover have "\<Theta> \<turnstile>\<^sub>w\<^sub>f ([]::\<Phi>)    \<and>  \<Theta> ; \<B> ; G\<turnstile>\<^sub>w\<^sub>f []\<^sub>\<Delta>" using wfD_emptyI wfPhi_emptyI infer_v_wf assms by auto
      ultimately show ?thesis using * wfCE_valI wfC_eqI by metis
    qed
    show "\<forall>i. wfI \<Theta> G i \<and> is_satis_g i G \<longrightarrow> is_satis i c[z::=v]\<^sub>c\<^sub>v" proof(rule,rule)
      fix i 
      assume \<open>wfI \<Theta> G i \<and> is_satis_g i G\<close>
      thus \<open>is_satis i c[z::=v]\<^sub>c\<^sub>v\<close> using * ** is_satis_eq by auto
    qed
  qed
qed

lemma subst_valid_simple: 
  fixes v::v
  assumes "\<Theta> ; \<B> ; G \<turnstile> v \<Rightarrow> \<lbrace> z0 : b | c0 \<rbrace>" and 
          "atom z0 \<sharp> c" and "atom z0 \<sharp> v"
          "\<Theta>; \<B> ; (z0,b,c0)#\<^sub>\<Gamma>G \<Turnstile> c[z::=V_var z0]\<^sub>c\<^sub>v" 
  shows " \<Theta> ; \<B> ; G \<Turnstile> c[z::=v]\<^sub>c\<^sub>v"
proof -
  have " \<Theta> ; \<B> ; G \<Turnstile> c0[z0::=v]\<^sub>c\<^sub>v"  using subst_self_valid assms by metis
  moreover have "atom z0 \<sharp> G" using assms valid_wf_all by meson
  moreover  have "wfV \<Theta> \<B> G v b" using infer_v_v_wf assms b_of.simps by metis
  moreover have "(c[z::=V_var z0]\<^sub>c\<^sub>v)[z0::=v]\<^sub>c\<^sub>v = c[z::=v]\<^sub>c\<^sub>v" using subst_v_simple_commute assms subst_v_c_def by metis
  ultimately show ?thesis  using valid_trans assms subst_defs by metis
qed

lemma wfI_subst1:
  assumes " wfI \<Theta> (G'[x::=v]\<^sub>\<Gamma>\<^sub>v @ G) i" and "wfG \<Theta> \<B> (G' @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> G)" and "eval_v i v sv" and "wfRCV \<Theta> sv b"
  shows "wfI \<Theta> (G' @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> G) ( i( x \<mapsto> sv))"
proof - 
  {
    fix xa::x and ba::b  and ca::c
    assume as: "(xa,ba,ca) \<in> setG ((G' @ ((x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> G)))"
    then have " \<exists>s. Some s = (i(x \<mapsto> sv)) xa \<and> wfRCV \<Theta> s ba"
    proof(cases "x=xa") 
      case True
      have "Some sv =  (i(x \<mapsto> sv)) x \<and> wfRCV \<Theta> sv b" using as assms wfI_def by auto
      moreover have "b=ba" using  assms as True wfG_member_unique by metis
      ultimately show ?thesis using True by auto
    next
      case False
     
      then obtain ca' where "(xa, ba, ca') \<in> setG (G'[x::=v]\<^sub>\<Gamma>\<^sub>v @ G)" using wfG_member_subst2 assms as by metis
      then obtain s where " Some s = i xa \<and> wfRCV \<Theta> s ba" using wfI_def assms False by blast
      thus  ?thesis using False by auto
    qed   
  }
  from this show ?thesis using wfI_def allI by blast 
qed

lemma subst_valid:
  fixes v::v and c'::c and \<Gamma> ::\<Gamma>
  assumes "\<Theta> ; \<B> ; \<Gamma> \<Turnstile> c[z::=v]\<^sub>c\<^sub>v" and  "\<Theta> ; \<B> ; \<Gamma>\<turnstile>\<^sub>w\<^sub>f v : b" and 
          "\<Theta> ; \<B>\<turnstile>\<^sub>w\<^sub>f \<Gamma>" and  "atom x \<sharp> c" and  "atom x \<sharp> \<Gamma>" and 
          "\<Theta> ; \<B>\<turnstile>\<^sub>w\<^sub>f (\<Gamma>'@(x,b,c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v ) #\<^sub>\<Gamma> \<Gamma>)" and          
          "\<Theta> ; \<B> ; \<Gamma>'@(x,b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v ) #\<^sub>\<Gamma> \<Gamma> \<Turnstile> c'" (is " \<Theta> ; \<B>;  ?G \<Turnstile> c'")
  shows   "\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma> \<Turnstile> c'[x::=v]\<^sub>c\<^sub>v"
proof -
  have *:"wfC \<Theta> \<B> (\<Gamma>'@(x,b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v ) #\<^sub>\<Gamma> \<Gamma>) c'"  using valid.simps assms by metis
  hence "wfC \<Theta> \<B> (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>) (c'[x::=v]\<^sub>c\<^sub>v)" using wf_subst(2)[OF *]  b_of.simps   assms subst_g_inside wfC_wf  by metis
  moreover have "\<forall>i. wfI \<Theta> (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>) i \<and> is_satis_g i (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>) \<longrightarrow> is_satis i (c'[x::=v]\<^sub>c\<^sub>v)" 

  proof(rule,rule)
    fix i
    assume as: " wfI \<Theta> (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>) i \<and> is_satis_g i (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>)"
    thm valid.simps
    hence wfig: "wfI \<Theta> \<Gamma> i" using wfI_suffix infer_v_wf assms by metis 
    then obtain s where s:"eval_v i v s" and b:"wfRCV \<Theta> s b" using eval_v_exist infer_v_v_wf b_of.simps assms by metis
    thm is_satis_g_i_upd2
    have is1: "is_satis_g ( i( x \<mapsto> s)) (\<Gamma>' @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" proof(rule is_satis_g_i_upd2)
      show "is_satis (i(x \<mapsto> s)) (c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v)" proof - 
        have "is_satis i  (c[z::=v]\<^sub>c\<^sub>v)" 
          using subst_valid_simple assms as valid.simps infer_v_wf assms
           is_satis_g_suffix wfI_suffix by metis
        hence "is_satis i ((c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v)[x::=v]\<^sub>c\<^sub>v)" using assms subst_v_simple_commute[of x c z v] subst_v_c_def by metis
        moreover have "\<Theta> ; \<B> ; (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma> \<turnstile>\<^sub>w\<^sub>f c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v" using wfC_refl wfG_suffix assms by metis
        moreover have "\<Theta> ; \<B> ; \<Gamma>\<turnstile>\<^sub>w\<^sub>f v : b" using assms infer_v_v_wf b_of.simps by metis
        ultimately show ?thesis using subst_c_satis[OF s , of \<Theta> \<B> x b  "c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v" \<Gamma> "c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v"] wfig by auto
      qed        
      show "atom x \<sharp> \<Gamma>" using assms by metis
      show "wfG \<Theta> \<B> (\<Gamma>' @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" using valid_wf_all assms by metis
      show "\<Theta> ; \<B> ; \<Gamma>\<turnstile>\<^sub>w\<^sub>f v : b" using assms infer_v_v_wf by force
      show "i \<lbrakk> v \<rbrakk> ~ s " using s by auto
      show "\<Theta> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile> i" using as by auto
      show "i \<Turnstile> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> " using as by auto
    qed
    hence "is_satis ( i( x \<mapsto> s)) c'" proof -
      have "wfI  \<Theta> (\<Gamma>' @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) ( i( x \<mapsto> s))" 
        using wfI_subst1[of \<Theta> \<Gamma>' x v  \<Gamma> i \<B> b c z  s] as b s assms  by metis
      thus ?thesis using is1 valid.simps assms by presburger
    qed

    thus "is_satis i (c'[x::=v]\<^sub>c\<^sub>v)" using subst_c_satis_full[OF s] valid.simps as infer_v_v_wf b_of.simps assms by metis 

  qed
  ultimately show ?thesis using valid.simps by auto
qed

lemma subst_valid_infer_v:
  fixes v::v and c'::c
  assumes  "\<Theta> ; \<B> ; G \<turnstile> v \<Rightarrow> \<lbrace> z0 : b | c0 \<rbrace>" and  "atom x \<sharp> c" and  "atom x \<sharp> G" and "wfG \<Theta> \<B> (G'@(x,b,c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v ) #\<^sub>\<Gamma> G)" and "atom z0 \<sharp> v"
           " \<Theta>;\<B>;(z0,b,c0)#\<^sub>\<Gamma>G \<Turnstile> c[z::=V_var z0]\<^sub>c\<^sub>v" and "atom z0 \<sharp> c" and
           " \<Theta>;\<B>;G'@(x,b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v ) #\<^sub>\<Gamma> G \<Turnstile> c'" (is " \<Theta> ; \<B>;  ?G \<Turnstile> c'")
         shows    " \<Theta>;\<B>;G'[x::=v]\<^sub>\<Gamma>\<^sub>v@G \<Turnstile> c'[x::=v]\<^sub>c\<^sub>v"
proof - 
  have "\<Theta> ; \<B> ; G \<Turnstile> c[z::=v]\<^sub>c\<^sub>v"  
    using infer_v_wf subst_valid_simple valid.simps assms    using subst_valid_simple assms valid.simps infer_v_wf assms
           is_satis_g_suffix wfI_suffix by metis
  moreover have "wfV \<Theta> \<B> G v b" and "wfG \<Theta> \<B> G" 
    using assms infer_v_wf b_of.simps apply metis  using assms infer_v_wf by metis
  ultimately show ?thesis using assms subst_valid by metis
qed


section \<open>Subtyping\<close>


lemma subst_subtype: 
 fixes v::v
 assumes "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> (\<lbrace>z0:b|c0\<rbrace>)" and
         " \<Theta>;\<B>;\<Gamma> \<turnstile> (\<lbrace>z0:b|c0\<rbrace>) \<lesssim>  (\<lbrace> z : b | c \<rbrace>)" and
         " \<Theta>;\<B>;\<Gamma>'@((x,b,c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> (\<lbrace> z1 : b1 | c1 \<rbrace>) \<lesssim> (\<lbrace> z2 : b1 | c2 \<rbrace>)" (is " \<Theta> ; \<B>; ?G1 \<turnstile> ?t1 \<lesssim> ?t2" ) and 
         "atom z \<sharp> (x,v) \<and> atom z0 \<sharp> (c,x,v,z,\<Gamma>) \<and> atom z1 \<sharp> (x,v) \<and> atom z2 \<sharp> (x,v)" and "wsV \<Theta> \<B> \<Gamma> v" 
       shows " \<Theta>;\<B>;\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma> \<turnstile>  \<lbrace> z1 : b1 | c1 \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v \<lesssim>  \<lbrace> z2 : b1 | c2 \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v"
proof -
  have z2: "atom z2 \<sharp> (x,v) " using assms by auto
  hence "x \<noteq> z2" by auto

  obtain xx::x where xxf: "atom xx \<sharp> (x,z1, c1, z2, c2, \<Gamma>' @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>, c1[x::=v]\<^sub>c\<^sub>v, c2[x::=v]\<^sub>c\<^sub>v, \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>, 
                (\<Theta> , \<B>  , \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>,   z1 , c1[x::=v]\<^sub>c\<^sub>v ,  z2 ,     c2[x::=v]\<^sub>c\<^sub>v  ))" (is "atom xx \<sharp> ?tup")
    using obtain_fresh by blast
  hence xxf2: "atom xx \<sharp> (z1, c1, z2, c2, \<Gamma>' @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" using fresh_prod9 fresh_prod5 by fast    

  have  vd1: " \<Theta>;\<B>;((xx, b1, c1[z1::=V_var xx]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>')[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<Turnstile> (c2[z2::=V_var xx]\<^sub>c\<^sub>v)[x::=v]\<^sub>c\<^sub>v"
  proof(rule subst_valid_infer_v[of \<Theta> _ _ _ z0 b c0 _ c, where z=z])
    show "\<Theta> ; \<B> ; \<Gamma>  \<turnstile> v \<Rightarrow> \<lbrace> z0 : b  | c0 \<rbrace>" using assms by auto

    show xf: "atom x \<sharp> \<Gamma>" using subtype_g_wf wfG_inside_fresh_suffix assms by metis

    show "atom x \<sharp> c" proof -
      have "wfT  \<Theta> \<B> \<Gamma> (\<lbrace> z : b | c \<rbrace>)" using subtype_wf[OF assms(2)] by auto
      moreover have "x \<noteq> z" using assms(4) 
        using fresh_Pair not_self_fresh by blast
      ultimately show ?thesis using xf wfT_fresh_c assms by presburger
    qed

    show " \<Theta> ; \<B>\<turnstile>\<^sub>w\<^sub>f ((xx, b1, c1[z1::=V_var xx]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>') @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma> "
    proof(subst append_g.simps,rule wfG_consI)
      show *: \<open> \<Theta> ; \<B>\<turnstile>\<^sub>w\<^sub>f \<Gamma>' @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma> \<close> using subtype_g_wf assms by metis
      show \<open>atom xx \<sharp> \<Gamma>' @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<close>  using xxf fresh_prod9 by metis
      show \<open> \<Theta> ; \<B>\<turnstile>\<^sub>w\<^sub>f b1 \<close> using subtype_elims[OF assms(3)] wfT_wfC wfC_wf wfG_cons by metis
      show "\<Theta> ; \<B> ; (xx, b1, TRUE) #\<^sub>\<Gamma> \<Gamma>' @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma> \<turnstile>\<^sub>w\<^sub>f c1[z1::=V_var xx]\<^sub>c\<^sub>v " proof(rule  wfT_wfC)
        have "\<lbrace> z1 : b1  | c1 \<rbrace> =  \<lbrace> xx : b1  | c1[z1::=V_var xx]\<^sub>c\<^sub>v \<rbrace> " using xxf fresh_prod9 type_eq_subst xxf2 fresh_prodN by metis
        thus "\<Theta> ; \<B> ; \<Gamma>' @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<lbrace> xx : b1  | c1[z1::=V_var xx]\<^sub>c\<^sub>v \<rbrace> " using subtype_wfT[OF assms(3)] by metis
        show "atom xx \<sharp> \<Gamma>' @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>" using xxf fresh_prod9 by metis
      qed       
    qed

    show "atom z0 \<sharp> v" using assms fresh_prod5 by auto
    have "\<Theta> ; \<B> ; (z0, b, c0) #\<^sub>\<Gamma> \<Gamma>  \<Turnstile> c[z::=V_var z0]\<^sub>v "     
      apply(rule obtain_fresh[of "(z0,c0, \<Gamma>, c, z)"],rule subtype_valid[OF assms(2), THEN valid_flip], 
         (fastforce simp add: assms fresh_prodN)+) done
    thus  "\<Theta> ; \<B> ; (z0, b, c0) #\<^sub>\<Gamma> \<Gamma>  \<Turnstile> c[z::=V_var z0]\<^sub>c\<^sub>v "   using subst_defs by auto

    show "atom z0 \<sharp> c" using assms fresh_prod5 by auto
    show "\<Theta> ; \<B> ; ((xx, b1, c1[z1::=V_var xx]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>') @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<Turnstile> c2[z2::=V_var xx]\<^sub>c\<^sub>v "
      using subtype_valid  assms(3) xxf xxf2 fresh_prodN append_g.simps subst_defs by metis
  qed

  have xfw1: "atom z1 \<sharp> v \<and> atom x \<sharp> [ xx ]\<^sup>v \<and> x \<noteq> z1" 
    apply(intro conjI)
    apply(simp add: assms xxf fresh_at_base fresh_prodN freshers fresh_x_neq)+
    using fresh_x_neq fresh_prodN xxf  apply blast
    using fresh_x_neq fresh_prodN assms by blast

  have xfw2: "atom z2 \<sharp> v \<and> atom x \<sharp> [ xx ]\<^sup>v \<and> x \<noteq> z2"     
    apply(auto simp add: assms xxf fresh_at_base fresh_prodN freshers)
    by(insert xxf fresh_at_base fresh_prodN assms, fast+) 

  have wf1: "wfT \<Theta> \<B> (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) (\<lbrace> z1 : b1  | c1[x::=v]\<^sub>c\<^sub>v \<rbrace>)" proof -
    have "wfT \<Theta> \<B> (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) (\<lbrace> z1 : b1  | c1 \<rbrace>)[x::=v]\<^sub>\<tau>\<^sub>v" 
      using wf_subst(4)  assms b_of.simps infer_v_v_wf subtype_wf subst_tv.simps subst_g_inside  wfT_wf by metis
    moreover have "atom z1 \<sharp> (x,v)" using assms by auto
    ultimately show ?thesis using subst_tv.simps by auto
  qed
  moreover have wf2: "wfT \<Theta> \<B> (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) (\<lbrace> z2 : b1  | c2[x::=v]\<^sub>c\<^sub>v \<rbrace>)" proof -
    have "wfT \<Theta> \<B> (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) (\<lbrace> z2 : b1  | c2 \<rbrace>)[x::=v]\<^sub>\<tau>\<^sub>v" using wf_subst(4)  assms b_of.simps infer_v_v_wf subtype_wf subst_tv.simps subst_g_inside  wfT_wf by metis
    moreover have "atom z2 \<sharp> (x,v)" using assms by auto
    ultimately show ?thesis using subst_tv.simps by auto
  qed
  moreover have "\<Theta> ; \<B> ; (xx, b1, c1[x::=v]\<^sub>c\<^sub>v[z1::=V_var xx]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> )  \<Turnstile> (c2[x::=v]\<^sub>c\<^sub>v)[z2::=V_var xx]\<^sub>c\<^sub>v" proof -
    have "xx \<noteq> x" using  xxf fresh_Pair fresh_at_base by fast
    hence "((xx, b1, subst_cv c1 z1 (V_var xx) ) #\<^sub>\<Gamma> \<Gamma>')[x::=v]\<^sub>\<Gamma>\<^sub>v = (xx, b1, (subst_cv c1 z1 (V_var xx) )[x::=v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v)"
      using subst_gv.simps by auto
    moreover have "(c1[z1::=V_var xx]\<^sub>c\<^sub>v )[x::=v]\<^sub>c\<^sub>v = (c1[x::=v]\<^sub>c\<^sub>v) [z1::=V_var xx]\<^sub>c\<^sub>v" using subst_cv_commute_subst xfw1 by metis
    moreover have "c2[z2::=[ xx ]\<^sup>v]\<^sub>c\<^sub>v[x::=v]\<^sub>c\<^sub>v  =  (c2[x::=v]\<^sub>c\<^sub>v)[z2::=V_var xx]\<^sub>c\<^sub>v" using subst_cv_commute_subst xfw2 by metis
    ultimately show ?thesis using  vd1  append_g.simps by metis
  qed
  moreover have "atom xx \<sharp> (\<Theta> , \<B>  , \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>,  z1 , c1[x::=v]\<^sub>c\<^sub>v ,  z2  ,c2[x::=v]\<^sub>c\<^sub>v  )" 
    using xxf fresh_prodN by metis
  ultimately have  "\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>  \<turnstile> \<lbrace> z1 : b1  | c1[x::=v]\<^sub>c\<^sub>v \<rbrace> \<lesssim> \<lbrace> z2 : b1  | c2[x::=v]\<^sub>c\<^sub>v \<rbrace>" 
     using subtype_baseI  subst_defs  by metis
  thus ?thesis using subst_tv.simps assms by presburger
qed

lemma subst_subtype_tau: 
 fixes v::v
 assumes   "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<tau>" and
           "\<Theta> ; \<B> ; \<Gamma> \<turnstile> \<tau> \<lesssim>  (\<lbrace> z : b | c \<rbrace>)"
           "\<Theta> ; \<B> ; \<Gamma>'@((x,b,c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> \<tau>1 \<lesssim> \<tau>2" and 
           "atom z \<sharp> (x,v)"
 shows "\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma> \<turnstile>  \<tau>1[x::=v]\<^sub>\<tau>\<^sub>v     \<lesssim>  \<tau>2[x::=v]\<^sub>\<tau>\<^sub>v"
proof - 
  obtain z0 and b0 and c0 where zbc0: "\<tau>=(\<lbrace> z0 : b0 | c0 \<rbrace>) \<and> atom z0 \<sharp> (c,x,v,z,\<Gamma>)" 
    using obtain_fresh_z by metis
  obtain z1 and b1 and c1 where zbc1: "\<tau>1=(\<lbrace> z1 : b1 | c1 \<rbrace>) \<and> atom z1 \<sharp> (x,v)"
    using obtain_fresh_z by metis
  obtain z2 and b2 and c2 where zbc2: "\<tau>2=(\<lbrace> z2 : b2 | c2 \<rbrace>) \<and> atom z2 \<sharp> (x,v)"
    using obtain_fresh_z by metis

  have "b0=b" using subtype_eq_base  zbc0 assms by blast

  hence vinf: "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<lbrace> z0 : b | c0 \<rbrace>" using assms zbc0 by blast
  have vsub: "\<Theta> ; \<B> ; \<Gamma> \<turnstile>\<lbrace> z0 : b | c0 \<rbrace> \<lesssim>  \<lbrace> z : b | c \<rbrace>" using assms zbc0 \<open>b0=b\<close> by blast
  have beq:"b1=b2" using subtype_eq_base 
    using zbc1 zbc2 assms by blast 
  have "\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> \<lbrace> z1 : b1  | c1 \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v \<lesssim> \<lbrace> z2 : b1  | c2 \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v" 
  proof(rule subst_subtype[OF vinf vsub] )
    show  "\<Theta> ; \<B> ; \<Gamma>'@((x,b,c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> \<lbrace> z1 : b1 | c1 \<rbrace> \<lesssim> \<lbrace> z2 : b1 | c2 \<rbrace>" 
        using beq assms zbc1 zbc2 by auto
    show "atom z \<sharp> (x, v) \<and> atom z0 \<sharp> (c, x, v, z, \<Gamma>) \<and> atom z1 \<sharp> (x, v) \<and> atom z2 \<sharp> (x, v)" 
      using zbc0 zbc1 zbc2 assms by blast
    show "wfV \<Theta> \<B> \<Gamma> v (b_of \<tau>)" using infer_v_wf assms by simp
  qed

  thus ?thesis using zbc1 zbc2 \<open>b1=b2\<close> assms by blast
qed

lemma subtype_if1:
  fixes v::v
  assumes "P ; \<B> ; \<Gamma>  \<turnstile> t1  \<lesssim> t2" and "wfV P \<B> \<Gamma> v (base_for_lit l)" and         
          "atom z1 \<sharp> v" and  "atom z2 \<sharp> v" and "atom z1 \<sharp> t1" and "atom z2 \<sharp> t2" and "atom z1 \<sharp> \<Gamma>" and "atom z2 \<sharp> \<Gamma>"
        shows   "P ; \<B> ; \<Gamma> \<turnstile> \<lbrace> z1 : b_of t1  | CE_val v  ==  CE_val (V_lit l)   IMP  (c_of t1 z1)  \<rbrace> \<lesssim> \<lbrace> z2 : b_of t2  | CE_val v  ==  CE_val (V_lit l) IMP  (c_of t2 z2)  \<rbrace>"
proof - 
  obtain z1' where t1: "t1 = \<lbrace> z1' : b_of t1 | c_of t1 z1'\<rbrace> \<and> atom z1' \<sharp> (z1,\<Gamma>,t1)" using obtain_fresh_z_c_of by metis
  obtain z2' where t2:  "t2 = \<lbrace> z2' : b_of t2 | c_of t2 z2'\<rbrace> \<and> atom z2' \<sharp> (z2,t2) " using obtain_fresh_z_c_of by metis
  have beq:"b_of t1 = b_of t2" using subtype_eq_base2 assms by auto

  have c1: "(c_of t1 z1')[z1'::=[ z1 ]\<^sup>v]\<^sub>c\<^sub>v = c_of t1 z1" using c_of_switch t1 assms by simp
  have c2: "(c_of t2 z2')[z2'::=[ z2 ]\<^sup>v]\<^sub>c\<^sub>v = c_of t2 z2" using c_of_switch t2 assms by simp

  have "P ; \<B> ; \<Gamma>  \<turnstile> \<lbrace> z1 : b_of t1  | [ v ]\<^sup>c\<^sup>e  ==  [ [ l ]\<^sup>v ]\<^sup>c\<^sup>e   IMP  (c_of t1 z1')[z1'::=[z1]\<^sup>v]\<^sub>v  \<rbrace> \<lesssim> \<lbrace> z2 : b_of t1  | [ v ]\<^sup>c\<^sup>e  ==  [ [ l ]\<^sup>v ]\<^sup>c\<^sup>e   IMP  (c_of t2 z2')[z2'::=[z2]\<^sup>v]\<^sub>v  \<rbrace>"
  proof(rule subtype_if)
    show \<open>P ; \<B> ; \<Gamma>  \<turnstile> \<lbrace> z1' : b_of t1  | c_of t1 z1' \<rbrace> \<lesssim> \<lbrace> z2' : b_of t1  | c_of t2 z2' \<rbrace>\<close> using t1 t2 assms beq by auto
    show \<open> P ; \<B> ; \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<lbrace> z1 : b_of t1  | [ v ]\<^sup>c\<^sup>e  ==  [ [ l ]\<^sup>v ]\<^sup>c\<^sup>e   IMP  (c_of t1 z1')[z1'::=[ z1 ]\<^sup>v]\<^sub>v  \<rbrace> \<close> using wfT_wfT_if_rev assms subtype_wfT c1 subst_defs by metis
    show \<open> P ; \<B> ; \<Gamma>  \<turnstile>\<^sub>w\<^sub>f \<lbrace> z2 : b_of t1  | [ v ]\<^sup>c\<^sup>e  ==  [ [ l ]\<^sup>v ]\<^sup>c\<^sup>e   IMP  (c_of t2 z2')[z2'::=[ z2 ]\<^sup>v]\<^sub>v  \<rbrace> \<close> using wfT_wfT_if_rev assms subtype_wfT c2 subst_defs beq by metis
    show \<open>atom z1 \<sharp> v\<close> using assms by auto
    show \<open>atom z1' \<sharp> \<Gamma>\<close> using t1 by auto
    show \<open>atom z1 \<sharp> c_of t1 z1'\<close> using t1 assms c_of_fresh by force
    show \<open>atom z2 \<sharp> c_of t2 z2'\<close> using t2 assms c_of_fresh by force
    show \<open>atom z2 \<sharp> v\<close> using assms by auto
  qed
  then show ?thesis using t1 t2 assms c1 c2 beq subst_defs by metis
qed


section \<open>Values\<close>

lemma subst_infer_aux:
  fixes \<tau>\<^sub>1::\<tau> and v'::v
  assumes "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<tau>\<^sub>1" and "\<Theta> ; \<B> ; \<Gamma>' \<turnstile> v' \<Rightarrow> \<tau>\<^sub>2" and "b_of \<tau>\<^sub>1 = b_of \<tau>\<^sub>2"
  shows "\<tau>\<^sub>1 = (\<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v)"
proof -
  obtain z1 and b1 where zb1: "\<tau>\<^sub>1 = (\<lbrace> z1 : b1 | C_eq (CE_val (V_var z1)) (CE_val (v'[x::=v]\<^sub>v\<^sub>v)) \<rbrace>) \<and> atom z1 \<sharp> ((CE_val (v'[x::=v]\<^sub>v\<^sub>v), CE_val v),v'[x::=v]\<^sub>v\<^sub>v)" 
    using infer_v_form_fresh[OF assms(1)] by fastforce
  obtain z2 and b2 where zb2: "\<tau>\<^sub>2 = (\<lbrace> z2 : b2 | C_eq (CE_val (V_var z2)) (CE_val v') \<rbrace>) \<and> atom z2 \<sharp> ((CE_val (v'[x::=v]\<^sub>v\<^sub>v), CE_val v,x,v),v')" 
    using infer_v_form_fresh [OF assms(2)] by fastforce
  have beq: "b1 = b2" using assms zb1 zb2 by simp

  hence "(\<lbrace> z2 : b2 | C_eq (CE_val (V_var z2)) (CE_val v') \<rbrace>)[x::=v]\<^sub>\<tau>\<^sub>v = (\<lbrace> z2 : b2 | C_eq (CE_val (V_var z2)) (CE_val (v'[x::=v]\<^sub>v\<^sub>v)) \<rbrace>)" 
    using subst_tv.simps subst_cv.simps subst_ev.simps  forget_subst_vv[of x "V_var z2"] zb2 by force 
  also have  "... = (\<lbrace> z1 : b1 | C_eq (CE_val (V_var z1)) (CE_val (v'[x::=v]\<^sub>v\<^sub>v)) \<rbrace>)" 
    using type_e_eq[of z2 "CE_val  (v'[x::=v]\<^sub>v\<^sub>v)"z1 b1 ] zb1 zb2 fresh_PairD(1) assms beq by metis
  finally show ?thesis using zb1  zb2 by argo
qed

lemma subst_t_b_eq:
  fixes x::x and v::v
  shows  "b_of (\<tau>[x::=v]\<^sub>\<tau>\<^sub>v) = b_of \<tau>"
proof - 
  obtain z and b and c where "\<tau> = \<lbrace> z : b | c \<rbrace> \<and> atom z \<sharp> (x,v)"
    using has_fresh_z by blast
  thus ?thesis using subst_tv.simps  by simp
qed

lemma fresh_g_fresh_v:
  fixes x::x
  assumes "atom x \<sharp> \<Gamma>" and "wfV \<Theta> \<B> \<Gamma> v b"
  shows "atom x \<sharp> v"
  using assms  wfV_supp wfX_wfY wfG_atoms_supp_eq fresh_def 
  by (metis wfV_x_fresh)

lemma infer_v_fresh_g_fresh_v:
  fixes x::x and \<Gamma>::\<Gamma> and v::v
  assumes "atom x \<sharp> \<Gamma>'@\<Gamma>" and "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<tau>" 
  shows "atom x \<sharp> v"
proof - 
  have "atom x \<sharp> \<Gamma>" using fresh_suffix assms by auto
  moreover have "wfV \<Theta> \<B> \<Gamma> v (b_of \<tau>)" using infer_v_wf assms by auto
  ultimately show ?thesis using fresh_g_fresh_v by metis
qed

lemma infer_v_fresh_g_fresh_xv:
  fixes xa::x and v::v and \<Gamma>::\<Gamma>
  assumes "atom xa \<sharp> \<Gamma>'@((x,b,c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>)" and "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<tau>" 
  shows "atom xa \<sharp> (x,v)"
proof -
  have "atom xa \<sharp> x" using assms  fresh_in_g fresh_def by blast
  moreover have "\<Gamma>'@((x,b,c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>) = ((\<Gamma>'@(x,b,c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>GNil)@\<Gamma>)" using append_g.simps append_g_assoc by simp
  moreover hence "atom xa \<sharp> v" using infer_v_fresh_g_fresh_v assms by metis
  ultimately show ?thesis by auto
qed

lemma wfG_subst_infer_v:
  fixes v::v
  assumes "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f \<Gamma>' @ (x, b, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>" and "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<tau>" and "b_of \<tau> = b"
  shows "\<Theta> ; \<B>\<turnstile>\<^sub>w\<^sub>f \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> "
  using wfG_subst_wfV infer_v_v_wf assms by auto

lemma fresh_subst_gv_inside:
  fixes \<Gamma>::\<Gamma>
  assumes "atom z \<sharp> \<Gamma>' @ (x, b\<^sub>1, c0[z0::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>" and "atom z \<sharp> v" 
  shows "atom z \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>" 
unfolding fresh_append_g  using fresh_append_g assms fresh_subst_gv fresh_GCons by metis
 
lemma subst_infer_v:
  fixes v::v and v'::v
  assumes "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<tau>\<^sub>1" and 
          "\<Theta> ; \<B> ; \<Gamma>'@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v' \<Rightarrow> \<tau>\<^sub>2" and 
          "\<Theta> ; \<B> ; \<Gamma> \<turnstile> \<tau>\<^sub>1 \<lesssim>  (\<lbrace> z0 : b\<^sub>1 | c0 \<rbrace>)" and "atom z0 \<sharp> (x,v)"
  shows "\<Theta> ; \<B> ; (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v)@\<Gamma>  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v  \<Rightarrow> \<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v"
using assms proof(nominal_induct "v'" avoiding: x v arbitrary: \<tau>\<^sub>2   rule: v.strong_induct)
  case (V_lit l)

  hence *:"  \<turnstile>  l \<Rightarrow> \<tau>\<^sub>2" using infer_v_elims by metis
  thm type_eq_flip obtain_fresh_z type_e_eq
  then obtain z b  where t: "\<tau>\<^sub>2 = \<lbrace> z : b  | CE_val (V_var z)  ==  CE_val (V_lit l)  \<rbrace> \<and> atom z \<sharp>  \<Gamma>' @ (x, b\<^sub>1, c0[z0::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>"
    using infer_l_form * by metis
  hence **: "\<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v = \<tau>\<^sub>2" proof -
    have "atom z \<sharp> (x,v)" using infer_v_fresh_g_fresh_xv[of z] V_lit infer_v_wf t by metis
    moreover have "atom x \<sharp> V_lit l" using v.fresh supp_l_empty fresh_def by fast
    ultimately show ?thesis using type_v_subst_fresh t by metis
  qed
  have "b_of \<tau>\<^sub>1 =  b\<^sub>1" using subtype_eq_base2 V_lit b_of.simps by auto

  show ?case
proof(subst subst_vv.simps , rule infer_v_litI)   
   
      show " \<turnstile> l \<Rightarrow> \<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v" using * ** by auto
      show "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> " using wfG_subst_infer_v V_lit \<open>b_of \<tau>\<^sub>1 =  b\<^sub>1\<close> by blast
    qed

next
  case (V_var y)
  have " b\<^sub>1 = b_of \<tau>\<^sub>1" using  subtype_eq_base2 assms b_of.simps by auto
  then obtain z and b and c where zb: "\<tau>\<^sub>2 = \<lbrace> z : b | CE_val (V_var z)  ==  CE_val (V_var y)  \<rbrace> \<and> 
     atom z \<sharp> y \<and> atom z \<sharp> (\<Gamma>' @ (x, b\<^sub>1, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) \<and> Some (b,c) = lookup (\<Gamma>' @ (x, b\<^sub>1, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) y"     
  proof -
    assume "\<And>z b c. \<tau>\<^sub>2 = \<lbrace> z : b | CE_val (V_var z) == CE_val (V_var y) \<rbrace> \<and> atom z \<sharp> y \<and>  
       atom z \<sharp> (\<Gamma>' @ (x, b\<^sub>1, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) \<and> Some (b, c) = lookup (\<Gamma>' @ (x, b\<^sub>1, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>) y \<Longrightarrow> thesis"
    then show ?thesis
     using infer_var3[OF V_var(2)]  by blast
  qed
  

  text \<open> If y is x then we are dealing with v otherwise substitution is identity \<close>

  have wfg1: "wfG \<Theta> \<B> (\<Gamma>'@(x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>)" using infer_v_wf using V_var by fast
  moreover have "wfV \<Theta> \<B> \<Gamma> v b\<^sub>1" using infer_v_v_wf V_var \<open>b\<^sub>1 = b_of \<tau>\<^sub>1\<close>  by auto
  ultimately have wfg: "wfG \<Theta> \<B> ((\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v)@\<Gamma>)" using wf_subst(3)[OF wfg1]  subst_g_inside  by metis

  have wsg1: "wfG \<Theta> \<B> (\<Gamma>'@(x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>)" using wfg1  by auto
  hence zf:"atom z \<sharp> ((\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v)@\<Gamma>)"  using wfG_xa_fresh_in_subst_v V_var zb subst_g_inside wsg1 subst_defs by metis

  show ?case proof(cases "x = y")
    case True
    have lu: "Some (b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) = lookup (\<Gamma>'@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v))#\<^sub>\<Gamma>\<Gamma>) x" using lookup_inside_wf wfg1  by metis
    
    moreover have "(V_var y)[x::=v]\<^sub>v\<^sub>v = v" by (simp add: True)

    moreover have "\<Theta> ; \<B> ; \<Gamma> \<turnstile> \<tau>\<^sub>1 \<lesssim> (\<tau>\<^sub>2 [x::=v]\<^sub>\<tau>\<^sub>v)" proof -
      have "\<tau>\<^sub>1 = (\<tau>\<^sub>2 [x::=v]\<^sub>\<tau>\<^sub>v)" using subst_infer_aux  [where x=x and v=v and v'="V_var y" and \<tau>\<^sub>1=\<tau>\<^sub>1 and \<tau>\<^sub>2=\<tau>\<^sub>2,OF _ V_var(2)] 
        by (metis Pair_inject True V_var.prems(1) V_var.prems(2) assms(3) b_of.simps calculation(2) infer_v_elims(1) infer_v_form lu option.inject subst_infer_aux subtype_eq_base)
      thus ?thesis using subtype_reflI infer_v_t_wf
        using assms subtype_reflI2 by metis
    qed

    ultimately have "\<Theta> ; \<B> ; \<Gamma>  \<turnstile> (V_var y)[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<tau>\<^sub>1 \<and> \<Theta> ; \<B> ; \<Gamma>  \<turnstile> \<tau>\<^sub>1 \<lesssim> \<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v" 
      using V_var True by argo
    moreover have "setG \<Gamma> \<subseteq> setG  (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>)" by simp
    moreover have "\<Theta> ; \<B>\<turnstile>\<^sub>w\<^sub>f (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>)" proof - 
      have "\<Theta> ; \<B>\<turnstile>\<^sub>w\<^sub>f \<Gamma>' @ (x, b\<^sub>1, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>" using infer_v_wf V_var by auto
      moreover have  "\<Theta> ; \<B> ; \<Gamma> \<turnstile>\<^sub>w\<^sub>f v : b_of \<tau>\<^sub>1" using infer_v_v_wf V_var by auto
      moreover have " b\<^sub>1 = b_of \<tau>\<^sub>1" using  subtype_eq_base2 assms b_of.simps by auto
      ultimately show ?thesis  using wf_subst(3) subst_g_inside  by metis
    qed
    ultimately show ?thesis using infer_v_g_weakening subtype_weakening wfg 
       append_g_assoc in_set_conv_decomp subset_code
      by (metis V_var.prems(2) subst_infer_aux subst_t_b_eq subtype_eq_base2)
  next
    case False

    have "(V_var y)[x::=v]\<^sub>v\<^sub>v = V_var y" by (simp add: False)

    have eq :"(V_var y)[x::=v]\<^sub>v\<^sub>v = V_var y" by (simp add: False)
    then obtain c' where  "Some (b,c') = lookup (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) y" using subst_lookup[of b c  \<Gamma>' x b\<^sub>1 "c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v" \<Gamma> y] zb False wfg1 V_var  by metis
    hence a1: "\<Theta> ; \<B> ; (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) \<turnstile> (V_var y) \<Rightarrow> (\<lbrace> z : b | CE_val (V_var z)  ==  CE_val (V_var y)  \<rbrace>)" 
      using  infer_v_varI[of \<Theta> _ _ b c' y z , OF wfg] wfg  zf zb by metis  
    moreover have "(\<lbrace> z : b | CE_val (V_var z)  ==  CE_val (V_var y)  \<rbrace>) = \<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v" proof -
      have "supp  \<tau>\<^sub>2 = { atom y } \<union> supp b" using zb supp_v_var_tau False by force
      hence "atom x \<sharp>  \<tau>\<^sub>2"  using False fresh_def by fastforce 
      thus ?thesis using forget_subst_tv zb by metis
    qed
    ultimately show ?thesis using subtype_reflI infer_v_t_wf  eq subtype_reflI2 by metis
  qed

next
  case (V_pair v\<^sub>1 v\<^sub>2)

  text \<open> Unpack into typing for parts \<close>
  then obtain \<tau>'\<^sub>1 and  \<tau>'\<^sub>2 and z where t1t2: "\<Theta> ; \<B> ; \<Gamma>'@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v\<^sub>1 \<Rightarrow> \<tau>'\<^sub>1 \<and> \<Theta> ; \<B> ; \<Gamma>'@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v\<^sub>2 \<Rightarrow> \<tau>'\<^sub>2 \<and> 
       (\<tau>\<^sub>2 = (\<lbrace> z :  B_pair (b_of \<tau>'\<^sub>1) (b_of \<tau>'\<^sub>2) |  ((CE_val (V_var z)) == (CE_val (V_pair v\<^sub>1 v\<^sub>2))) \<rbrace>))" 
    using infer_v_pair2E by meson

  text \<open> Apply IH and repack to get required typing judgement \<close>
  have t1'': "\<Theta> ; \<B> ; (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) \<turnstile> v\<^sub>1[x::=v]\<^sub>v\<^sub>v \<Rightarrow>  \<tau>'\<^sub>1[x::=v]\<^sub>\<tau>\<^sub>v" using V_pair t1t2 by auto
  moreover have  t2'':"\<Theta> ; \<B> ; (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) \<turnstile> v\<^sub>2[x::=v]\<^sub>v\<^sub>v \<Rightarrow>  \<tau>'\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v" using V_pair t1t2 by auto
  ultimately obtain \<tau>\<^sub>3 where t3: "\<Theta> ; \<B> ; (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) \<turnstile> V_pair (v\<^sub>1[x::=v]\<^sub>v\<^sub>v) (v\<^sub>2[x::=v]\<^sub>v\<^sub>v) \<Rightarrow> \<tau>\<^sub>3 \<and> (b_of \<tau>\<^sub>3 = B_pair (b_of \<tau>'\<^sub>1) (b_of \<tau>'\<^sub>2))" 
    using infer_v_pair2I subst_tbase_eq by metis

  text \<open> Show required subtyping judgement \<close>

  moreover  have "\<tau>\<^sub>3  = (\<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v) " proof -
      have veq: " V_pair (v\<^sub>1[x::=v]\<^sub>v\<^sub>v) (v\<^sub>2[x::=v]\<^sub>v\<^sub>v) =  (V_pair v\<^sub>1 v\<^sub>2)[x::=v]\<^sub>v\<^sub>v" using subst_vv.simps by presburger
      have  "\<Theta> ; \<B> ; (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) \<turnstile>  (V_pair v\<^sub>1 v\<^sub>2)[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<tau>\<^sub>3 " using veq t3 by simp
      moreover have  "\<Theta> ; \<B> ; \<Gamma>'@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> (V_pair v\<^sub>1 v\<^sub>2) \<Rightarrow> \<tau>\<^sub>2" using V_pair by simp   
      moreover have "b_of \<tau>\<^sub>3  = b_of \<tau>\<^sub>2" proof -
        have "b_of \<tau>\<^sub>3 = B_pair (b_of \<tau>'\<^sub>1) (b_of \<tau>'\<^sub>2)" using t3  by auto
        moreover have "b_of \<tau>'\<^sub>1 = b_of \<tau>'\<^sub>1[x::=v]\<^sub>\<tau>\<^sub>v" using t1'' subst_tbase_eq
          by (metis \<tau>.exhaust b_of.simps)
        moreover have "b_of \<tau>'\<^sub>2 = b_of \<tau>'\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v" using t2'' subst_tbase_eq 
          by (metis \<tau>.exhaust b_of.simps)
        moreover have  "b_of \<tau>'\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v = b_of \<tau>'\<^sub>2 \<and> b_of \<tau>'\<^sub>1[x::=v]\<^sub>\<tau>\<^sub>v = b_of \<tau>'\<^sub>1" 
          using subst_t_b_eq by auto
        ultimately show ?thesis using t1t2 b_of.simps by metis
      qed
      ultimately show ?thesis using subst_infer_aux by meson
    qed

  ultimately show ?case using subst_vv.simps by auto

next
  case (V_cons s dc w)

  text \<open> Proof outline: unpack using elimination, apply IH to type of w and then repack using infer v consI \<close>

  have eq1: "(V_cons s dc w)[x::=v]\<^sub>v\<^sub>v =  V_cons s dc (w[x::=v]\<^sub>v\<^sub>v)" using subst_vv.simps by presburger

  obtain  dclist x2 b2 c2 z' c' z where *:"
    \<tau>\<^sub>2 = \<lbrace> z : B_id s  | CE_val (V_var z)  ==  CE_val (V_cons s dc w)  \<rbrace> \<and>
    AF_typedef s dclist \<in> set \<Theta> \<and>
    (dc, \<lbrace> x2 : b2  | c2 \<rbrace>) \<in> set dclist \<and>
     (\<Theta> ; \<B> ; \<Gamma>' @ (x, b\<^sub>1, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> w \<Rightarrow> \<lbrace> z' : b2  | c' \<rbrace>) \<and> 
    (\<Theta> ; \<B> ; \<Gamma>' @ (x, b\<^sub>1, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> \<lbrace> z' : b2  | c' \<rbrace> \<lesssim> \<lbrace> x2 : b2  | c2 \<rbrace>) \<and> 
    atom z \<sharp> w \<and> atom z \<sharp> \<Gamma>' @ (x, b\<^sub>1, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>"
    using infer_v_elims(4)[OF V_cons(3)] by metis

  obtain \<tau>\<^sub>3' where yy: "\<Theta> ; \<B> ; (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) \<turnstile>  w[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z' : b2  | c' \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v " 
    using V_cons (1)[of v x "\<lbrace> z' : b2  | c' \<rbrace>"] using V_cons * by auto
  then obtain z3 b3 c3 where yy2: "atom z3 \<sharp> (x,v) \<and> \<lbrace> z' : b2  | c' \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v = \<lbrace> z3 : b3 | c3 \<rbrace>" using obtain_fresh_z by metis

  hence "b2=b3" using subtype_eq_base2 yy subst_tbase_eq b_of.simps by metis

  have zvf: "atom z \<sharp> (x,v)" using infer_v_fresh_g_fresh_xv  * V_cons  infer_v_wf by blast
  hence zf: "atom z \<sharp> CE_val (V_cons s dc (w[x::=v]\<^sub>v\<^sub>v))"  
    unfolding ce.fresh v.fresh   by(simp add: pure_fresh *)

  obtain z0'::x where z0:"atom z0' \<sharp>  (x,v,w[x::=v]\<^sub>v\<^sub>v, \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>,CE_val (V_cons s dc (w[x::=v]\<^sub>v\<^sub>v)))" using obtain_fresh by metis
  hence  zf2: "atom z0' \<sharp> CE_val (V_cons s dc (w[x::=v]\<^sub>v\<^sub>v))" using e.fresh fresh_Pair v.fresh pure_fresh fresh_prod5 by metis
  hence zeq: "\<lbrace> z : B_id s |  CE_val (V_var z)  ==  CE_val (V_cons s dc (w[x::=v]\<^sub>v\<^sub>v))  \<rbrace> = 
          \<lbrace> z0' : B_id s |  CE_val (V_var z0')  ==  CE_val (V_cons s dc (w[x::=v]\<^sub>v\<^sub>v))  \<rbrace>" using type_e_eq zf e.fresh fresh_Pair by metis
  moreover have teq: "\<lbrace> z : B_id s |  CE_val (V_var z)  ==  CE_val (V_cons s dc (w[x::=v]\<^sub>v\<^sub>v))  \<rbrace> =  \<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v" 
    using * subst_tv.simps subst_ev.simps subst_vv.simps zvf by simp
   
  have **:"\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> V_cons s dc w[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z0' : B_id s |  CE_val (V_var z0')  ==  CE_val (V_cons s dc (w[x::=v]\<^sub>v\<^sub>v))  \<rbrace>"
  proof 
    show \<open>AF_typedef s dclist \<in> set \<Theta>\<close> using * by auto
    show \<open>(dc, \<lbrace> x2 : b2  | c2 \<rbrace>) \<in> set dclist\<close> using * by auto
    show ***:\<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> w[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z3 : b2  | c3 \<rbrace>\<close> using yy yy2 \<open>b2=b3\<close> by auto
    show \<open>\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> \<lbrace> z3 : b2  | c3 \<rbrace> \<lesssim> \<lbrace> x2 : b2  | c2 \<rbrace>\<close> proof -
      have xx:" \<Theta> ; \<B> ; \<Gamma>'@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>)  \<turnstile>\<lbrace> z' : b2  | c' \<rbrace> \<lesssim> \<lbrace> x2 : b2  | c2 \<rbrace>" using * by auto
      hence "\<Theta> ; \<B> ; (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) \<turnstile>  \<lbrace> z' : b2  | c' \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v \<lesssim> \<lbrace> x2 : b2  | c2 \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v" using subst_subtype_tau[OF V_cons(2) assms(3) xx  V_cons(5)]  by auto
      moreover have "\<turnstile>\<^sub>w\<^sub>f \<Theta>" using infer_v_wf   * by auto
      moreover hence " \<lbrace> x2 : b2  | c2 \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v = \<lbrace> x2 : b2  | c2 \<rbrace>" using wfTh_wfT2 * forget_subst_tv fresh_def wfG_nilI by fast
      moreover have "\<Theta> ; \<B> ; (\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>) \<turnstile>\<lbrace> z3 : b2  | c3 \<rbrace> \<lesssim>  \<lbrace> z' : b2  | c' \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v" using yy yy2 \<open>b2=b3\<close> subtype_reflI infer_v_t_wf[OF ***]  by metis
      ultimately show ?thesis using subtype_trans by metis
    qed
    show \<open>atom z0' \<sharp> w[x::=v]\<^sub>v\<^sub>v\<close> using z0 fresh_Pair by metis
    show \<open>atom z0' \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<close> using z0 by auto
  qed

  moreover hence "\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> \<lbrace> z0' : B_id s |  CE_val (V_var z0')  ==  CE_val (V_cons s dc (w[x::=v]\<^sub>v\<^sub>v))  \<rbrace> \<lesssim> \<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v" 
    using subtype_reflI teq zeq infer_v_t_wf by metis

  ultimately show ?case using zeq teq by auto
next
  case (V_consp s dc b w)
  from  V_consp(3) V_consp(1,2,4,5) show ?case 
  proof(nominal_induct "\<Gamma>' @ (x, b\<^sub>1, c0[z0::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>" "V_consp s dc b w" \<tau>\<^sub>2 avoiding: x v rule: infer_v.strong_induct)
    case (infer_v_conspI bv dclist \<Theta> tc \<B> tv z)

    have "\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile> (V_consp s dc b w[x::=v]\<^sub>v\<^sub>v) \<Rightarrow> \<lbrace> z : B_app s b  | [ [ z ]\<^sup>v ]\<^sup>c\<^sup>e  ==  [ V_consp s dc b w[x::=v]\<^sub>v\<^sub>v ]\<^sup>c\<^sup>e  \<rbrace>"
    proof(rule Typing.infer_v_conspI[OF infer_v_conspI(5,6)] )   
      show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile> w[x::=v]\<^sub>v\<^sub>v \<Rightarrow> tv[x::=v]\<^sub>\<tau>\<^sub>v\<close> proof -
        have "atom z0 \<sharp> (x, v) " using  infer_v_conspI by metis
        hence "\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile> w[x::=v]\<^sub>v\<^sub>v \<Rightarrow> tv[x::=v]\<^sub>\<tau>\<^sub>v" 
          using infer_v_conspI(21) infer_v_conspI(24) infer_v_conspI(3) infer_v_conspI by metis
        thus ?thesis using subst_tv.simps by auto
      qed
      show \<open>\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> tv[x::=v]\<^sub>\<tau>\<^sub>v \<lesssim> tc[bv::=b]\<^sub>\<tau>\<^sub>b\<close> proof -       
        have "\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile> tv[x::=v]\<^sub>\<tau>\<^sub>v \<lesssim> tc[bv::=b]\<^sub>\<tau>\<^sub>b[x::=v]\<^sub>\<tau>\<^sub>v" 
          using infer_v_conspI subst_subtype_tau by metis
        moreover have "atom x \<sharp> tc[bv::=b]\<^sub>\<tau>\<^sub>b" proof -
          have "supp tc \<subseteq> { atom bv }" using wfTh_poly_lookup_supp infer_v_conspI wfX_wfY by metis
          hence "atom x \<sharp> tc" using x_not_in_b_set 
            using fresh_def by fastforce
          moreover have "atom x \<sharp> b" using x_fresh_b by auto
          ultimately show ?thesis using fresh_subst_if subst_b_\<tau>_def by metis
        qed
        ultimately show ?thesis using forget_subst_v subst_v_\<tau>_def by metis
      qed
      show \<open>atom z \<sharp> (\<Theta>, \<B>, \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>, w[x::=v]\<^sub>v\<^sub>v, b)\<close>  proof -
        have "atom z \<sharp> w[x::=v]\<^sub>v\<^sub>v" using fresh_subst_v_if infer_v_conspI subst_v_v_def by metis
        moreover have "atom z \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>"  using fresh_subst_gv_inside infer_v_conspI by metis
        ultimately show ?thesis using fresh_prodN infer_v_conspI by metis
      qed
      show \<open>atom bv \<sharp> (\<Theta>, \<B>, \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>, w[x::=v]\<^sub>v\<^sub>v, b)\<close>  proof -
        have "atom bv \<sharp> w[x::=v]\<^sub>v\<^sub>v" using fresh_subst_v_if infer_v_conspI subst_v_v_def by metis
        moreover have "atom bv \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>"  using fresh_subst_gv_inside infer_v_conspI by metis
        ultimately show ?thesis using fresh_prodN infer_v_conspI by metis
      qed
      show \<open> \<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f b \<close> using infer_v_conspI by metis
    qed
    moreover have "atom z \<sharp> (x,v)" using infer_v_conspI fresh_Pair by metis
    ultimately show ?case using  subst_vv.simps subst_tv.simps by auto
  qed
qed

lemma subst_infer_check_v:
  fixes v::v and v'::v
  assumes "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<tau>\<^sub>1"  and
          "check_v \<Theta> \<B> (\<Gamma>'@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>))  v' \<tau>\<^sub>2"  and
          "\<Theta> ; \<B> ; \<Gamma> \<turnstile> \<tau>\<^sub>1 \<lesssim>  \<lbrace> z0 : b\<^sub>1 | c0 \<rbrace>" and "atom z0 \<sharp> (x,v)"
  shows "check_v \<Theta> \<B> ((\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v)@\<Gamma>)  (v'[x::=v]\<^sub>v\<^sub>v) (\<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v)"
proof -
  obtain \<tau>\<^sub>2' where t2: "infer_v  \<Theta> \<B>  (\<Gamma>' @ (x, b\<^sub>1, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)  v' \<tau>\<^sub>2' \<and>  \<Theta> ; \<B> ; (\<Gamma>' @ (x, b\<^sub>1, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)  \<turnstile> \<tau>\<^sub>2' \<lesssim> \<tau>\<^sub>2"
    using check_v_elims assms by blast
  hence "infer_v \<Theta> \<B> ((\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v)@\<Gamma>)  (v'[x::=v]\<^sub>v\<^sub>v)  (\<tau>\<^sub>2'[x::=v]\<^sub>\<tau>\<^sub>v)"
    using subst_infer_v[OF assms(1) _ assms(3) assms(4)] by blast
  moreover hence "\<Theta>;  \<B> ; ((\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v)@\<Gamma>) \<turnstile>\<tau>\<^sub>2'[x::=v]\<^sub>\<tau>\<^sub>v \<lesssim>  \<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v" 
    using subst_subtype assms t2 by (meson subst_subtype_tau subtype_trans)
  ultimately show ?thesis using check_v.intros by blast
qed

lemma type_veq_subst[simp]:
  assumes "atom z \<sharp> (x,v)"
  shows "\<lbrace> z : b | CE_val (V_var z)  ==  CE_val v'  \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v = \<lbrace> z : b | CE_val (V_var z)  ==  CE_val v'[x::=v]\<^sub>v\<^sub>v  \<rbrace>"
  using assms by auto

lemma subst_infer_v_form:
  fixes v::v and v'::v and \<Gamma>::\<Gamma>
  assumes  "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<tau>\<^sub>1" and 
           "\<Theta> ; \<B> ; \<Gamma>'@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v' \<Rightarrow> \<tau>\<^sub>2" and "b= b_of \<tau>\<^sub>2"
          "\<Theta> ; \<B> ; \<Gamma> \<turnstile> \<tau>\<^sub>1 \<lesssim>  (\<lbrace> z0 : b\<^sub>1 | c0 \<rbrace>)" and "atom z0 \<sharp> (x,v)" and "atom z3' \<sharp> (x,v,v', \<Gamma>'@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>) )"
  shows \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z3' : b | CE_val (V_var z3')  ==  CE_val v'[x::=v]\<^sub>v\<^sub>v  \<rbrace>\<close>
proof - 
  have "\<Theta> ; \<B> ; \<Gamma>'@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>) \<turnstile> v' \<Rightarrow> \<lbrace> z3' : b_of \<tau>\<^sub>2 |  C_eq (CE_val (V_var z3')) (CE_val v') \<rbrace>" 
  proof(rule infer_v_form4)
    show \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b\<^sub>1, c0[z0::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma> \<turnstile> v' \<Rightarrow> \<tau>\<^sub>2\<close> using assms by metis
    show \<open>atom z3' \<sharp> (v', \<Gamma>' @ (x, b\<^sub>1, c0[z0::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)\<close> using assms fresh_prodN by metis
    show \<open>b_of \<tau>\<^sub>2 = b_of \<tau>\<^sub>2\<close> by auto
  qed
  hence \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z3' : b_of \<tau>\<^sub>2 | CE_val (V_var z3')  ==  CE_val v'  \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v\<close> 
    using subst_infer_v assms by metis
  thus ?thesis using type_veq_subst fresh_prodN assms by metis
qed


section \<open>Expressions\<close>

text \<open>
    For operator, fst and snd cases, we use elimination to get one or more values, apply the substitution lemma for values. The types always have
the same form and are equal under substitution.
    For function application, the subst value is a subtype of the value which is a subtype of the argument. The return of the function is the same
    under substitution.
\<close>


text \<open> Observe a similar pattern for each case \<close>

lemma subst_infer_e:
  fixes v::v and e::e and \<Gamma>'::\<Gamma>
  assumes 
          "\<Theta> ; \<Phi> ; \<B> ; G ; \<Delta> \<turnstile> e \<Rightarrow> \<tau>\<^sub>2" and "G = (\<Gamma>'@((x,b\<^sub>1,subst_cv c0 z0 (V_var x))#\<^sub>\<Gamma>\<Gamma>))"
          "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<tau>\<^sub>1" and 
          "\<Theta>;  \<B> ; \<Gamma> \<turnstile> \<tau>\<^sub>1 \<lesssim>  \<lbrace> z0 : b\<^sub>1 | c0 \<rbrace>" and "atom z0 \<sharp> (x,v)"
  shows "\<Theta> ; \<Phi> ; \<B> ; ((\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v)@\<Gamma>) ; (\<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v)  \<turnstile> (subst_ev e x v )  \<Rightarrow> \<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v"
using assms proof(nominal_induct  avoiding: x v rule: infer_e.strong_induct)
  case (infer_e_valI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v' \<tau>)

  have "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> ;  \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v   \<turnstile> (AE_val (v'[x::=v]\<^sub>v\<^sub>v)) \<Rightarrow> \<tau>[x::=v]\<^sub>\<tau>\<^sub>v"  
  proof
    show "\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v"  using wfD_subst infer_e_valI subtype_eq_base2 
      by (metis b_of.simps infer_v_v_wf subst_g_inside_simple wfD_wf wf_subst(11))
    show "\<Theta>\<turnstile>\<^sub>w\<^sub>f \<Phi>" using infer_e_valI by auto
    show "\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<tau>[x::=v]\<^sub>\<tau>\<^sub>v" using subst_infer_v infer_e_valI using wfD_subst infer_e_valI subtype_eq_base2 
      by metis
  qed       
  thus ?case using subst_ev.simps by simp
next
  case (infer_e_plusI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v1 z1 c1 v2 z2 c2 z3)

  hence z3f: "atom z3 \<sharp> CE_op Plus [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e" using e.fresh ce.fresh opp.fresh by metis
 
  obtain z3'::x where *:"atom z3' \<sharp> (x,v,AE_op Plus v1 v2,   CE_op Plus [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e , AE_op Plus v1[x::=v]\<^sub>v\<^sub>v v2[x::=v]\<^sub>v\<^sub>v , CE_op Plus [v1[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e [v2[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e,\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> )" 
    using obtain_fresh by metis
  hence  **:"(\<lbrace> z3 : B_int  | CE_val (V_var z3)  ==  CE_op Plus [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e  \<rbrace>) = \<lbrace> z3' : B_int  | CE_val (V_var z3')  ==  CE_op Plus [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e  \<rbrace>" 
    using type_e_eq  infer_e_plusI fresh_Pair z3f by metis

  obtain z1' b1' c1' where  z1:"atom z1' \<sharp> (x,v) \<and> \<lbrace> z1 : B_int | c1 \<rbrace> = \<lbrace> z1' : b1' | c1' \<rbrace>" using obtain_fresh_z by metis
  obtain z2' b2'  c2' where z2:"atom z2' \<sharp> (x,v) \<and> \<lbrace> z2 : B_int | c2 \<rbrace> = \<lbrace> z2' : b2' | c2' \<rbrace>" using obtain_fresh_z by metis

  have bb:"b1' = B_int \<and> b2' = B_int" using z1 z2 \<tau>.eq_iff by metis

  have "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> (AE_op Plus (v1[x::=v]\<^sub>v\<^sub>v) (v2[x::=v]\<^sub>v\<^sub>v)) \<Rightarrow> \<lbrace> z3' : B_int  | CE_val (V_var z3')  ==  CE_op Plus ([v1[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e) ([v2[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e)  \<rbrace>"
  proof 
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<close> 
      using infer_e_plusI wfD_subst subtype_eq_base2 b_of.simps by metis
    show \<open> \<Theta>\<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using  infer_e_plusI by blast
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v1[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z1' : B_int  | c1'[x::=v]\<^sub>c\<^sub>v \<rbrace>\<close> using subst_tv.simps subst_infer_v infer_e_plusI z1 bb by metis
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v2[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z2' : B_int  | c2'[x::=v]\<^sub>c\<^sub>v \<rbrace>\<close> using subst_tv.simps subst_infer_v infer_e_plusI z2 bb by metis
    show \<open>atom z3' \<sharp> AE_op Plus v1[x::=v]\<^sub>v\<^sub>v v2[x::=v]\<^sub>v\<^sub>v\<close> using fresh_prod6 * by metis
    show \<open>atom z3' \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<close> using * by auto
  qed
  moreover have "\<lbrace> z3' : B_int  | CE_val (V_var z3')  ==  CE_op Plus ([v1[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e) ([v2[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e)  \<rbrace> = \<lbrace> z3' : B_int  | CE_val (V_var z3')  ==  CE_op Plus [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e  \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v"
    by(subst subst_tv.simps,auto simp add: * )
  ultimately show ?case using subst_ev.simps * ** by metis
next
  case (infer_e_leqI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v1 z1 c1 v2 z2 c2 z3)

  hence z3f: "atom z3 \<sharp> CE_op LEq [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e" using e.fresh ce.fresh opp.fresh by metis

  obtain z3'::x where *:"atom z3' \<sharp> (x,v,AE_op LEq v1 v2, CE_op LEq [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e , CE_op LEq [v1[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e [v2[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e , AE_op LEq v1[x::=v]\<^sub>v\<^sub>v v2[x::=v]\<^sub>v\<^sub>v,\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> )"  
    using obtain_fresh by metis
  hence  **:"(\<lbrace> z3 : B_bool  | CE_val (V_var z3)  ==  CE_op LEq [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e  \<rbrace>) = \<lbrace> z3' : B_bool  | CE_val (V_var z3')  ==  CE_op LEq [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e  \<rbrace>" 
    using type_e_eq  infer_e_leqI fresh_Pair z3f by metis

  obtain z1' b1' c1' where  z1:"atom z1' \<sharp> (x,v) \<and> \<lbrace> z1 : B_int | c1 \<rbrace> = \<lbrace> z1' : b1' | c1' \<rbrace>" using obtain_fresh_z by metis
  obtain z2' b2'  c2' where z2:"atom z2' \<sharp> (x,v) \<and> \<lbrace> z2 : B_int | c2 \<rbrace> = \<lbrace> z2' : b2' | c2' \<rbrace>" using obtain_fresh_z by metis

  have bb:"b1' = B_int \<and> b2' = B_int" using z1 z2 \<tau>.eq_iff by metis

  have "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> (AE_op LEq (v1[x::=v]\<^sub>v\<^sub>v) (v2[x::=v]\<^sub>v\<^sub>v)) \<Rightarrow> \<lbrace> z3' : B_bool  | CE_val (V_var z3')  ==  CE_op LEq ([v1[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e) ([v2[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e)  \<rbrace>"
  proof 
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<close> using wfD_subst infer_e_leqI subtype_eq_base2 b_of.simps by metis
    show \<open> \<Theta>\<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using  infer_e_leqI(2) by auto 
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v1[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z1' : B_int  | c1'[x::=v]\<^sub>c\<^sub>v \<rbrace>\<close> using subst_tv.simps subst_infer_v infer_e_leqI z1 bb by metis
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v2[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z2' : B_int  | c2'[x::=v]\<^sub>c\<^sub>v \<rbrace>\<close> using subst_tv.simps subst_infer_v infer_e_leqI z2 bb by metis
    show \<open>atom z3' \<sharp> AE_op LEq v1[x::=v]\<^sub>v\<^sub>v v2[x::=v]\<^sub>v\<^sub>v\<close> using fresh_Pair * by metis
    show \<open>atom z3' \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<close> using * by auto
  qed
  moreover have "\<lbrace> z3' : B_bool  | CE_val (V_var z3')  ==  CE_op LEq ([v1[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e) ([v2[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e)  \<rbrace> = \<lbrace> z3' : B_bool  | CE_val (V_var z3')  ==  CE_op LEq [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e  \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v"
    using subst_tv.simps subst_ev.simps * by auto
  ultimately show ?case using subst_ev.simps * ** by metis
next
  case (infer_e_appI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> f x' b c \<tau>' s' v' \<tau>)

  hence "x \<noteq> x'" using \<open>atom x' \<sharp> \<Gamma>''\<close> using wfG_inside_x_neq wfX_wfY by metis

  show ?case proof(subst subst_ev.simps,rule)
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<close> using infer_e_appI wfD_subst subtype_eq_base2 b_of.simps by metis
    show \<open> \<Theta>\<turnstile>\<^sub>w\<^sub>f \<Phi> \<close>  using  infer_e_appI by metis
    show \<open>Some (AF_fundef f (AF_fun_typ_none (AF_fun_typ x' b c \<tau>' s'))) = lookup_fun \<Phi> f\<close> using  infer_e_appI by metis
    (*show \<open>\<Theta> ; \<B> ; (x', b, c) #\<^sub>\<Gamma> GNil\<turnstile>\<^sub>w\<^sub>f \<tau>'\<close> using  infer_e_appI by auto*)

    have \<open>\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Leftarrow> \<lbrace> x' : b  | c \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v\<close> proof(rule subst_infer_check_v )
      show "\<Theta> ; \<B> ; \<Gamma>  \<turnstile> v \<Rightarrow> \<tau>\<^sub>1" using infer_e_appI by metis
      show "\<Theta> ; \<B> ; \<Gamma>' @ (x, b\<^sub>1, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v' \<Leftarrow> \<lbrace> x' : b  | c \<rbrace>" using infer_e_appI by metis
      show "\<Theta> ; \<B> ; \<Gamma>  \<turnstile> \<tau>\<^sub>1 \<lesssim> \<lbrace> z0 : b\<^sub>1  | c0 \<rbrace>" using infer_e_appI by metis
      show "atom z0 \<sharp> (x, v)" using infer_e_appI by metis
    qed
    moreover have "atom x \<sharp> c" using wfPhi_f_supp_c[OF infer_e_appI(3)] fresh_def \<open>x\<noteq>x'\<close> 
      by (metis atom_eq_iff empty_iff infer_e_appI.hyps(2) insert_iff subset_singletonD)

    moreover hence "atom x \<sharp> \<lbrace> x' : b  | c \<rbrace>" using \<tau>.fresh supp_b_empty fresh_def by blast
    ultimately show  \<open>\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Leftarrow> \<lbrace> x' : b  | c \<rbrace>\<close> using forget_subst_tv by metis

    have "atom x' \<sharp> (x,v)" using infer_v_fresh_g_fresh_xv infer_e_appI check_v_wf by blast

    thus  \<open>atom x' \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<close>  using infer_e_appI fresh_subst_gv  wfD_wf subst_g_inside fresh_Pair by metis
    have "supp \<tau>' \<subseteq> { atom x' } \<union> supp \<B>" using infer_e_appI wfT_supp wfPhi_f_simple_wfT 
      by (meson infer_e_appI.hyps(2) le_supI1 wfPhi_f_simple_supp_t)
    hence "atom x \<sharp> \<tau>'" using  \<open>x\<noteq>x'\<close> fresh_def supp_at_base x_not_in_b_set  by fastforce
    thus  \<open>\<tau>'[x'::=v'[x::=v]\<^sub>v\<^sub>v]\<^sub>v = \<tau>[x::=v]\<^sub>\<tau>\<^sub>v\<close> using subst_tv_commute infer_e_appI subst_defs by metis
  qed
next
  case (infer_e_appPI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> b' f bv x' b c \<tau>' s' v' \<tau>)

  hence "x \<noteq> x'" using \<open>atom x' \<sharp> \<Gamma>''\<close> using wfG_inside_x_neq wfX_wfY by metis

  show ?case proof(subst subst_ev.simps,rule)
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<close>  using infer_e_appPI wfD_subst subtype_eq_base2 b_of.simps by metis
    show \<open> \<Theta>\<turnstile>\<^sub>w\<^sub>f \<Phi> \<close>  using  infer_e_appPI(4) by auto
    show "\<Theta> ; \<B> \<turnstile>\<^sub>w\<^sub>f b'"  using  infer_e_appPI(5) by auto
    show "Some (AF_fundef f (AF_fun_typ_some bv (AF_fun_typ x' b c \<tau>' s'))) = lookup_fun \<Phi> f"  using  infer_e_appPI(6) by auto

    show "\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Leftarrow> \<lbrace> x' : b[bv::=b']\<^sub>b  | c[bv::=b']\<^sub>b \<rbrace>" proof -
       have \<open>\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Leftarrow> \<lbrace> x' : b[bv::=b']\<^sub>b\<^sub>b  | c[bv::=b']\<^sub>c\<^sub>b \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v\<close> proof(rule subst_infer_check_v )
         show "\<Theta> ; \<B> ; \<Gamma>  \<turnstile> v \<Rightarrow> \<tau>\<^sub>1" using infer_e_appPI by metis
         show "\<Theta> ; \<B> ; \<Gamma>' @ (x, b\<^sub>1, c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> v' \<Leftarrow> \<lbrace> x' : b[bv::=b']\<^sub>b\<^sub>b  | c[bv::=b']\<^sub>c\<^sub>b \<rbrace>" using infer_e_appPI subst_defs by metis
         show "\<Theta> ; \<B> ; \<Gamma>  \<turnstile> \<tau>\<^sub>1 \<lesssim> \<lbrace> z0 : b\<^sub>1  | c0 \<rbrace>" using infer_e_appPI by metis
         show "atom z0 \<sharp> (x, v)" using infer_e_appPI by metis
       qed
       moreover have "atom x \<sharp> c"  proof -
         have "supp c \<subseteq> {atom x', atom bv}" using  wfPhi_f_poly_supp_c[OF infer_e_appPI(6)] infer_e_appPI by metis
         thus ?thesis unfolding fresh_def using  \<open>x\<noteq>x'\<close>  atom_eq_iff by auto
       qed
       moreover hence "atom x \<sharp> \<lbrace> x' : b[bv::=b']\<^sub>b\<^sub>b  | c[bv::=b']\<^sub>c\<^sub>b \<rbrace>" using \<tau>.fresh supp_b_empty fresh_def subst_b_fresh_x 
         by (metis subst_b_c_def)
       ultimately show ?thesis using forget_subst_tv subst_defs by metis
     qed
     have "supp \<tau>' \<subseteq> { atom x', atom bv }" using  wfPhi_f_poly_supp_t infer_e_appPI by metis
     hence "atom x \<sharp> \<tau>'" using fresh_def \<open>x\<noteq>x'\<close> by force
     hence *:"atom x \<sharp> \<tau>'[bv::=b']\<^sub>\<tau>\<^sub>b" using    subst_b_fresh_x subst_b_\<tau>_def by metis
    have "atom x' \<sharp> (x,v)" using infer_v_fresh_g_fresh_xv infer_e_appPI check_v_wf by blast
    thus  "atom x' \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>" using infer_e_appPI fresh_subst_gv  wfD_wf subst_g_inside fresh_Pair by metis
    show "\<tau>'[bv::=b']\<^sub>b[x'::=v'[x::=v]\<^sub>v\<^sub>v]\<^sub>v = \<tau>[x::=v]\<^sub>\<tau>\<^sub>v"  using  infer_e_appPI subst_tv_commute[OF * ] subst_defs by metis
    show "atom bv \<sharp> (\<Theta>, \<Phi>, \<B>, \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>, \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v, b', v'[x::=v]\<^sub>v\<^sub>v, \<tau>[x::=v]\<^sub>\<tau>\<^sub>v)" 
     (* Methodical breakdown by subgoals to direct the proof to the facts/methods we know work rather than use auto across all and
        try to clean up what is left. Convert this to Eisbach method using pattern matching to know which steps to use to solve a subgoal  *)
      apply(unfold fresh_prodN, intro conjI)
         apply(simp add: infer_e_appPI)
         apply(simp add: infer_e_appPI)
         apply(simp add: infer_e_appPI)
         apply(subst subst_g_inside[symmetric])  
            apply((insert infer_e_appPI wfX_wfY) [1], fast)
            apply(metis fresh_subst_gv_if infer_e_appPI)
         apply(simp add: fresh_prodN fresh_subst_dv_if infer_e_appPI)
         apply(simp add: infer_e_appPI)
         apply(simp add: fresh_prodN fresh_subst_v_if subst_v_v_def infer_e_appPI)
         apply(simp add: fresh_prodN fresh_subst_v_if subst_v_\<tau>_def infer_e_appPI)
      done

  qed
next
  case (infer_e_fstI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v' z' b1 b2 c z)

  hence zf: "atom z \<sharp> CE_fst [v']\<^sup>c\<^sup>e" using ce.fresh e.fresh opp.fresh by metis

  obtain z3'::x where *:"atom z3' \<sharp> (x,v,AE_fst v', CE_fst [v']\<^sup>c\<^sup>e , AE_fst v'[x::=v]\<^sub>v\<^sub>v ,\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> )" using obtain_fresh by auto
  hence  **:"(\<lbrace> z : b1  | CE_val (V_var z)  ==  CE_fst [v']\<^sup>c\<^sup>e  \<rbrace>) = \<lbrace> z3' : b1  | CE_val (V_var z3')  ==  CE_fst [v']\<^sup>c\<^sup>e  \<rbrace>" 
    using type_e_eq  infer_e_fstI(4) fresh_Pair zf by metis

  obtain z1' b1' c1' where  z1:"atom z1' \<sharp> (x,v) \<and> \<lbrace> z' : B_pair b1 b2 | c \<rbrace> = \<lbrace> z1' : b1' | c1' \<rbrace>" using obtain_fresh_z by metis

  have bb:"b1' = B_pair b1 b2" using z1 \<tau>.eq_iff by metis
  have "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v   \<turnstile> (AE_fst v'[x::=v]\<^sub>v\<^sub>v)  \<Rightarrow> \<lbrace> z3' : b1  | CE_val (V_var z3')  ==  CE_fst [v'[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e  \<rbrace>"
  proof 
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<close> using wfD_subst infer_e_fstI  subtype_eq_base2 b_of.simps by metis
    show \<open> \<Theta>\<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using  infer_e_fstI by metis
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z1' : B_pair b1 b2 | c1'[x::=v]\<^sub>c\<^sub>v \<rbrace>\<close> using subst_tv.simps subst_infer_v infer_e_fstI z1 bb by metis
    
    show \<open>atom z3' \<sharp> AE_fst v'[x::=v]\<^sub>v\<^sub>v \<close> using fresh_Pair * by metis
    show \<open>atom z3' \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<close> using * by auto
  qed
  moreover have "\<lbrace> z3' : b1  | CE_val (V_var z3')  ==  CE_fst [v'[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e \<rbrace> = \<lbrace> z3' : b1  | CE_val (V_var z3')  ==  CE_fst [v']\<^sup>c\<^sup>e  \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v"
    using subst_tv.simps subst_ev.simps * by auto
  ultimately show ?case using subst_ev.simps * ** by metis 
next
  case (infer_e_sndI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v' z' b1 b2 c z)
  hence zf: "atom z \<sharp> CE_snd [v']\<^sup>c\<^sup>e" using ce.fresh e.fresh opp.fresh by metis

  obtain z3'::x where *:"atom z3' \<sharp> (x,v,AE_snd v', CE_snd [v']\<^sup>c\<^sup>e , AE_snd v'[x::=v]\<^sub>v\<^sub>v ,\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> ,v', \<Gamma>'')" using obtain_fresh by auto
  hence  **:"(\<lbrace> z : b2  | CE_val (V_var z)  ==  CE_snd [v']\<^sup>c\<^sup>e  \<rbrace>) = \<lbrace> z3' : b2  | CE_val (V_var z3')  ==  CE_snd [v']\<^sup>c\<^sup>e  \<rbrace>" 
    using type_e_eq  infer_e_sndI(4) fresh_Pair zf by metis

  obtain z1' b2' c1' where  z1:"atom z1' \<sharp> (x,v) \<and> \<lbrace> z' : B_pair b1 b2 | c \<rbrace> = \<lbrace> z1' : b2' | c1' \<rbrace>" using obtain_fresh_z by metis

  have bb:"b2' = B_pair b1 b2" using z1 \<tau>.eq_iff by metis

  have "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v   \<turnstile> (AE_snd (v'[x::=v]\<^sub>v\<^sub>v))  \<Rightarrow> \<lbrace> z3' : b2  | CE_val (V_var z3')  ==  CE_snd ([v'[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e)  \<rbrace>"
  proof 
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<close> using wfD_subst infer_e_sndI  subtype_eq_base2 b_of.simps by metis
    show \<open> \<Theta>\<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using  infer_e_sndI by metis
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z1' : B_pair b1 b2 | c1'[x::=v]\<^sub>c\<^sub>v \<rbrace>\<close> using subst_tv.simps subst_infer_v infer_e_sndI z1 bb by metis
    
    show \<open>atom z3' \<sharp> AE_snd v'[x::=v]\<^sub>v\<^sub>v \<close> using fresh_Pair * by metis
    show \<open>atom z3' \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<close> using * by auto
  qed
  moreover have "\<lbrace> z3' : b2  | CE_val (V_var z3')  ==  CE_snd ([v'[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e) \<rbrace> = \<lbrace> z3' : b2  | CE_val (V_var z3')  ==  CE_snd [v']\<^sup>c\<^sup>e  \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v"
    by(subst subst_tv.simps, auto simp add: fresh_prodN *)
  ultimately show ?case using subst_ev.simps * ** by metis 
next
  case (infer_e_lenI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v' z' c z)
  hence zf: "atom z \<sharp> CE_len [v']\<^sup>c\<^sup>e" using ce.fresh e.fresh opp.fresh by metis
  obtain z3'::x where *:"atom z3' \<sharp> (x,v,AE_len v', CE_len [v']\<^sup>c\<^sup>e , AE_len v'[x::=v]\<^sub>v\<^sub>v ,\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> , \<Gamma>'',v')" using obtain_fresh by auto
  hence  **:"(\<lbrace> z : B_int  | CE_val (V_var z)  ==  CE_len [v']\<^sup>c\<^sup>e  \<rbrace>) = \<lbrace> z3' : B_int  | CE_val (V_var z3')  ==  CE_len [v']\<^sup>c\<^sup>e  \<rbrace>" 
    using type_e_eq  infer_e_lenI fresh_Pair zf by metis

  have ***: "\<Theta> ; \<B> ; \<Gamma>''  \<turnstile> v' \<Rightarrow> \<lbrace> z3' : B_bitvec  | CE_val (V_var z3') == CE_val v' \<rbrace>" 
    using infer_e_lenI infer_v_form3[OF infer_e_lenI(3), of z3'] b_of.simps * fresh_Pair by metis

  have "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v   \<turnstile> (AE_len (v'[x::=v]\<^sub>v\<^sub>v))  \<Rightarrow> \<lbrace> z3' : B_int | CE_val (V_var z3')  ==  CE_len ([v'[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e)  \<rbrace>" 
  proof
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<close>  using wfD_subst infer_e_lenI  subtype_eq_base2 b_of.simps by metis
    show \<open> \<Theta>\<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using  infer_e_lenI by metis

    have \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z3' : B_bitvec  | CE_val (V_var z3')  ==  CE_val v'  \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v\<close> 
    proof(rule subst_infer_v)
      show \<open> \<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<tau>\<^sub>1\<close> using infer_e_lenI by metis
      show  \<open> \<Theta> ; \<B> ; \<Gamma>' @ (x, b\<^sub>1, c0[z0::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma> \<turnstile> v' \<Rightarrow> \<lbrace> z3' : B_bitvec  | [ [ z3' ]\<^sup>v ]\<^sup>c\<^sup>e  ==  [ v' ]\<^sup>c\<^sup>e  \<rbrace>\<close> using *** infer_e_lenI by metis
      show "\<Theta> ; \<B> ; \<Gamma>  \<turnstile> \<tau>\<^sub>1 \<lesssim> \<lbrace> z0 : b\<^sub>1  | c0 \<rbrace>" using infer_e_lenI by metis
      show "atom z0 \<sharp> (x, v)" using infer_e_lenI by metis
   qed
   
   thus  \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z3' : B_bitvec  | CE_val (V_var z3')  ==  CE_val v'[x::=v]\<^sub>v\<^sub>v  \<rbrace>\<close> 
     using  subst_tv.simps subst_ev.simps fresh_Pair * fresh_prodN subst_vv.simps by auto

    show \<open>atom z3' \<sharp> AE_len v'[x::=v]\<^sub>v\<^sub>v\<close> using fresh_Pair * by metis
    show \<open>atom z3' \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<close> using fresh_Pair * by metis
  qed

  moreover have "\<lbrace> z3' : B_int | CE_val (V_var z3')  ==  CE_len ([v'[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e) \<rbrace> = \<lbrace> z3' : B_int  | CE_val (V_var z3')  ==  CE_len [v']\<^sup>c\<^sup>e  \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v"
    using subst_tv.simps subst_ev.simps * by auto

  ultimately show ?case using subst_ev.simps *  ** by metis 
next
  case (infer_e_mvarI \<Theta> \<B> \<Gamma>'' \<Phi> \<Delta> u \<tau>)

  have "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v   \<turnstile> (AE_mvar u) \<Rightarrow> \<tau>[x::=v]\<^sub>\<tau>\<^sub>v" 
  proof
    show \<open> \<Theta> ; \<B>\<turnstile>\<^sub>w\<^sub>f \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<close>  proof - 
      have "wfV \<Theta> \<B> \<Gamma> v (b_of \<tau>\<^sub>1)" using infer_v_wf infer_e_mvarI by auto
      moreover have "b_of \<tau>\<^sub>1 = b\<^sub>1" using subtype_eq_base2 infer_e_mvarI b_of.simps by simp
      ultimately show ?thesis using wf_subst(3)[OF infer_e_mvarI(1), of \<Gamma>' x b\<^sub>1 "c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v" \<Gamma> v] infer_e_mvarI subst_g_inside by metis
    qed
    show \<open> \<Theta>\<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using infer_e_mvarI  by auto
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<close> using wfD_subst infer_e_mvarI  subtype_eq_base2 b_of.simps by metis
    show \<open>(u, \<tau>[x::=v]\<^sub>\<tau>\<^sub>v) \<in> setD \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v\<close>  using infer_e_mvarI  subst_dv_member by metis
  qed
  moreover have " (AE_mvar u) =  (AE_mvar u)[x::=v]\<^sub>e\<^sub>v" using subst_ev.simps by auto
  ultimately show ?case by auto

next
  case (infer_e_concatI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v1 z1 c1 v2 z2 c2 z3)

  hence zf: "atom z3 \<sharp> CE_concat [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e" using ce.fresh e.fresh opp.fresh by metis 

  obtain z3'::x where *:"atom z3' \<sharp> (x,v,v1,v2,AE_concat v1 v2, CE_concat [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e , AE_concat (v1[x::=v]\<^sub>v\<^sub>v) (v2[x::=v]\<^sub>v\<^sub>v) ,\<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> , \<Gamma>'',v1 , v2)" using obtain_fresh by auto

  hence  **:"(\<lbrace> z3 : B_bitvec  | CE_val (V_var z3)  ==  CE_concat [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e \<rbrace>) = \<lbrace> z3' : B_bitvec  | CE_val (V_var z3')  ==  CE_concat [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e  \<rbrace>" 
    using type_e_eq  infer_e_concatI fresh_Pair zf by metis
  have zfx: "atom x \<sharp> z3'"  using fresh_at_base fresh_prodN * by auto

  have v1: "\<Theta> ; \<B> ; \<Gamma>''  \<turnstile> v1 \<Rightarrow> \<lbrace> z3' : B_bitvec  | CE_val (V_var z3') == CE_val v1 \<rbrace>" 
    using infer_e_concatI infer_v_form3 b_of.simps * fresh_Pair by metis
  have v2: "\<Theta> ; \<B> ; \<Gamma>''  \<turnstile> v2 \<Rightarrow> \<lbrace> z3' : B_bitvec  | CE_val (V_var z3') == CE_val v2 \<rbrace>" 
    using infer_e_concatI infer_v_form3 b_of.simps * fresh_Pair by metis

  have "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v   \<turnstile> (AE_concat (v1[x::=v]\<^sub>v\<^sub>v) (v2[x::=v]\<^sub>v\<^sub>v))  \<Rightarrow> \<lbrace> z3' : B_bitvec | CE_val (V_var z3')  ==  CE_concat ([v1[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e) ([v2[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e)  \<rbrace>" 
  proof
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<close>  using wfD_subst infer_e_concatI  subtype_eq_base2 b_of.simps by metis
    show \<open> \<Theta>\<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> by(simp add: infer_e_concatI) 
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v1[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z3' : B_bitvec  | CE_val (V_var z3')  ==  CE_val (v1[x::=v]\<^sub>v\<^sub>v)  \<rbrace>\<close>
      using subst_infer_v_form infer_e_concatI fresh_prodN * b_of.simps by metis
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>  \<turnstile> v2[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z3' : B_bitvec  | CE_val (V_var z3')  ==  CE_val (v2[x::=v]\<^sub>v\<^sub>v)  \<rbrace>\<close>   
      using subst_infer_v_form infer_e_concatI fresh_prodN * b_of.simps by metis
    show \<open>atom z3' \<sharp> AE_concat v1[x::=v]\<^sub>v\<^sub>v  v2[x::=v]\<^sub>v\<^sub>v\<close> using fresh_Pair * by metis
    show \<open>atom z3' \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<close> using fresh_Pair * by metis
  qed

  moreover have "\<lbrace> z3' : B_bitvec | CE_val (V_var z3')  ==  CE_concat ([v1[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e) ([v2[x::=v]\<^sub>v\<^sub>v]\<^sup>c\<^sup>e) \<rbrace> = \<lbrace> z3' : B_bitvec  | CE_val (V_var z3')  ==  CE_concat [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e  \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v"
    using subst_tv.simps subst_ev.simps * by auto

  ultimately show ?case using subst_ev.simps ** * by metis
next
  thm subst_tv.simps
  case (infer_e_splitI \<Theta> \<B> \<Gamma>'' \<Delta> \<Phi> v1 z1 c1 v2 z2 z3)
  hence *:"atom z3 \<sharp> (x,v)" using fresh_Pair by auto
  have \<open>x \<noteq> z3 \<close> using infer_e_splitI by force
  have " \<Theta> ; \<Phi> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @
                  \<Gamma> ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> AE_split v1[x::=v]\<^sub>v\<^sub>v v2[x::=v]\<^sub>v\<^sub>v \<Rightarrow> 
               \<lbrace> z3 : [ B_bitvec , B_bitvec ]\<^sup>b  | [ v1[x::=v]\<^sub>v\<^sub>v ]\<^sup>c\<^sup>e  ==  [ [#1[ [ z3 ]\<^sup>v ]\<^sup>c\<^sup>e]\<^sup>c\<^sup>e @@ [#2[ [ z3 ]\<^sup>v ]\<^sup>c\<^sup>e]\<^sup>c\<^sup>e ]\<^sup>c\<^sup>e   AND  
                     [| [#1[ [ z3 ]\<^sup>v ]\<^sup>c\<^sup>e]\<^sup>c\<^sup>e |]\<^sup>c\<^sup>e  ==  [ v2[x::=v]\<^sub>v\<^sub>v ]\<^sup>c\<^sup>e   \<rbrace>"
  proof
    show \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<close>  using wfD_subst infer_e_splitI  subtype_eq_base2 b_of.simps by metis
    show \<open> \<Theta>  \<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using infer_e_splitI by auto
    have  \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile> v1[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z1 : B_bitvec  | c1 \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v\<close> 
       using subst_infer_v infer_e_splitI by metis
    thus \<open> \<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma> \<turnstile> v1[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<lbrace> z1 : B_bitvec  | c1[x::=v]\<^sub>c\<^sub>v \<rbrace>\<close> 
      using infer_e_splitI subst_tv.simps fresh_Pair by metis
    have \<open>x \<noteq> z2 \<close> using infer_e_splitI by force
    have "(\<lbrace> z2 : B_int  | ([ leq [ [ L_num 0 ]\<^sup>v ]\<^sup>c\<^sup>e [ [ z2 ]\<^sup>v ]\<^sup>c\<^sup>e ]\<^sup>c\<^sup>e  ==  [ [ L_true ]\<^sup>v ]\<^sup>c\<^sup>e)   
                     AND  ([ leq [ [ z2 ]\<^sup>v ]\<^sup>c\<^sup>e [| [ v1[x::=v]\<^sub>v\<^sub>v ]\<^sup>c\<^sup>e |]\<^sup>c\<^sup>e ]\<^sup>c\<^sup>e  ==  [ [ L_true ]\<^sup>v ]\<^sup>c\<^sup>e )  \<rbrace>) = 
         (\<lbrace> z2 : B_int  | ([ leq [ [ L_num  0 ]\<^sup>v ]\<^sup>c\<^sup>e [ [ z2 ]\<^sup>v ]\<^sup>c\<^sup>e ]\<^sup>c\<^sup>e  ==  [ [ L_true ]\<^sup>v ]\<^sup>c\<^sup>e )  
                     AND  ([ leq [ [ z2 ]\<^sup>v ]\<^sup>c\<^sup>e [| [ v1 ]\<^sup>c\<^sup>e |]\<^sup>c\<^sup>e ]\<^sup>c\<^sup>e  ==  [ [ L_true ]\<^sup>v ]\<^sup>c\<^sup>e )  \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v)"
      unfolding subst_cv.simps subst_cev.simps subst_vv.simps using \<open>x \<noteq> z2\<close> infer_e_splitI fresh_Pair by simp
(* subst_tv.simps subst_infer_check_v fresh_Pair subst_tv.simps subst_cv.simps subst_cev.simps 
               subst_vv.simps *)
    thus  \<open>\<Theta> ; \<B> ; \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @
                 \<Gamma>  \<turnstile> v2[x::=v]\<^sub>v\<^sub>v \<Leftarrow> \<lbrace> z2 : B_int  | [ leq [ [ L_num 0 ]\<^sup>v ]\<^sup>c\<^sup>e [ [ z2 ]\<^sup>v ]\<^sup>c\<^sup>e ]\<^sup>c\<^sup>e  ==  [ [ L_true ]\<^sup>v ]\<^sup>c\<^sup>e   
                     AND  [ leq [ [ z2 ]\<^sup>v ]\<^sup>c\<^sup>e [| [ v1[x::=v]\<^sub>v\<^sub>v ]\<^sup>c\<^sup>e |]\<^sup>c\<^sup>e ]\<^sup>c\<^sup>e  ==  [ [ L_true ]\<^sup>v ]\<^sup>c\<^sup>e   \<rbrace>\<close>
      using infer_e_splitI  subst_infer_check_v fresh_Pair by metis

    show \<open>atom z1 \<sharp> AE_split v1[x::=v]\<^sub>v\<^sub>v v2[x::=v]\<^sub>v\<^sub>v\<close> using infer_e_splitI fresh_subst_vv_if by auto
    show \<open>atom z2 \<sharp> AE_split v1[x::=v]\<^sub>v\<^sub>v v2[x::=v]\<^sub>v\<^sub>v\<close> using infer_e_splitI fresh_subst_vv_if by auto
    show \<open>atom z3 \<sharp> AE_split v1[x::=v]\<^sub>v\<^sub>v v2[x::=v]\<^sub>v\<^sub>v\<close> using infer_e_splitI fresh_subst_vv_if by auto
   
    show \<open>atom z3 \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<close>  using   fresh_subst_gv_inside infer_e_splitI by metis
    show \<open>atom z2 \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<close>  using   fresh_subst_gv_inside infer_e_splitI by metis
    show \<open>atom z1 \<sharp> \<Gamma>'[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<close>  using   fresh_subst_gv_inside infer_e_splitI by metis
  qed
  thus ?case apply (subst subst_tv.simps)
    using infer_e_splitI fresh_Pair apply metis
    unfolding subst_tv.simps subst_ev.simps subst_cv.simps subst_cev.simps subst_vv.simps * 
    using \<open>x \<noteq> z3\<close> by simp
qed


lemma infer_e_uniqueness:
  assumes "\<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>  \<turnstile> e\<^sub>1 \<Rightarrow> \<tau>\<^sub>1" and "\<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>  \<turnstile> e\<^sub>1 \<Rightarrow> \<tau>\<^sub>2"
  shows "\<tau>\<^sub>1 = \<tau>\<^sub>2"
using assms proof(nominal_induct rule:e.strong_induct)
  case (AE_val x)
  then show ?case using infer_e_elims(7)[OF AE_val(1)] infer_e_elims(7)[OF AE_val(2)] infer_v_uniqueness by metis
next
  case (AE_app f v)

  obtain x1 b1 c1 s1' \<tau>1' where t1: "Some (AF_fundef f (AF_fun_typ_none (AF_fun_typ x1 b1 c1 \<tau>1' s1'))) = lookup_fun \<Phi> f \<and>  \<tau>\<^sub>1 = \<tau>1'[x1::=v]\<^sub>\<tau>\<^sub>v" using  infer_e_app2E[OF AE_app(1)] by metis
  moreover obtain x2 b2 c2 s2' \<tau>2' where t2: "Some (AF_fundef f (AF_fun_typ_none (AF_fun_typ x2 b2 c2 \<tau>2' s2'))) = lookup_fun \<Phi> f \<and>  \<tau>\<^sub>2 = \<tau>2'[x2::=v]\<^sub>\<tau>\<^sub>v" using  infer_e_app2E[OF AE_app(2)] by metis

  have "\<tau>1'[x1::=v]\<^sub>\<tau>\<^sub>v = \<tau>2'[x2::=v]\<^sub>\<tau>\<^sub>v" using t1 and t2  fun_ret_unique by metis
  thus ?thesis using t1 t2 by auto
next
  case (AE_appP f b v)
  obtain bv1 x1 b1 c1 s1' \<tau>1' where t1: "Some (AF_fundef f (AF_fun_typ_some bv1 (AF_fun_typ x1 b1 c1 \<tau>1' s1'))) = lookup_fun \<Phi> f \<and>  \<tau>\<^sub>1 = \<tau>1'[bv1::=b]\<^sub>\<tau>\<^sub>b[x1::=v]\<^sub>\<tau>\<^sub>v" using  infer_e_appP2E[OF AE_appP(1)] by metis
  moreover obtain bv2 x2 b2 c2 s2' \<tau>2' where t2: "Some (AF_fundef f (AF_fun_typ_some bv2 (AF_fun_typ x2 b2 c2 \<tau>2' s2'))) = lookup_fun \<Phi> f \<and>  \<tau>\<^sub>2 = \<tau>2'[bv2::=b]\<^sub>\<tau>\<^sub>b[x2::=v]\<^sub>\<tau>\<^sub>v" using  infer_e_appP2E[OF AE_appP(2)] by metis

  have "\<tau>1'[bv1::=b]\<^sub>\<tau>\<^sub>b[x1::=v]\<^sub>\<tau>\<^sub>v = \<tau>2'[bv2::=b]\<^sub>\<tau>\<^sub>b[x2::=v]\<^sub>\<tau>\<^sub>v" using t1 and t2  fun_poly_ret_unique by metis
  thus ?thesis using t1 t2 by auto
next
  case (AE_op opp v1 v2)
  show ?case proof(cases "opp=Plus")
    case True
    hence "\<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>   \<turnstile> AE_op Plus v1 v2 \<Rightarrow> \<tau>\<^sub>1" and  "\<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>   \<turnstile> AE_op Plus v1 v2 \<Rightarrow> \<tau>\<^sub>2" using AE_op by auto
    thm infer_e_elims(3)
    thus ?thesis using infer_e_elims(11)[OF \<open>\<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>   \<turnstile> AE_op Plus v1 v2 \<Rightarrow> \<tau>\<^sub>1\<close> ] infer_e_elims(11)[OF \<open>\<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>   \<turnstile> AE_op Plus v1 v2 \<Rightarrow> \<tau>\<^sub>2\<close> ]
      by force
  next
    case False
    hence "opp = LEq" using opp.strong_exhaust by auto
    hence "\<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>   \<turnstile> AE_op LEq v1 v2 \<Rightarrow> \<tau>\<^sub>1" and  "\<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>   \<turnstile> AE_op LEq v1 v2 \<Rightarrow> \<tau>\<^sub>2" using AE_op by auto
    thm infer_e_elims(3)
    thus ?thesis using infer_e_elims(12)[OF \<open>\<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>   \<turnstile> AE_op LEq v1 v2 \<Rightarrow> \<tau>\<^sub>1\<close> ] infer_e_elims(12)[OF \<open>\<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>   \<turnstile> AE_op LEq v1 v2 \<Rightarrow> \<tau>\<^sub>2\<close> ]
      by force
  qed
next
  case (AE_concat v1 v2)

  obtain z3::x where t1:"\<tau>\<^sub>1 = \<lbrace> z3 : B_bitvec  | [ [ z3 ]\<^sup>v ]\<^sup>c\<^sup>e  ==  CE_concat [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e  \<rbrace> \<and> atom z3 \<sharp> v1 \<and> atom z3 \<sharp> v2 " using infer_e_elims(18)[OF AE_concat(1)] by metis
  obtain z3'::x where t2:"\<tau>\<^sub>2 = \<lbrace> z3' : B_bitvec  | [ [ z3' ]\<^sup>v ]\<^sup>c\<^sup>e  ==  CE_concat [v1]\<^sup>c\<^sup>e [v2]\<^sup>c\<^sup>e  \<rbrace> \<and> atom z3' \<sharp> v1 \<and> atom z3' \<sharp> v2" using infer_e_elims(18)[OF AE_concat(2)] by metis

  thus ?case using t1 t2 type_e_eq ce.fresh by metis

next
  case (AE_fst v)

  obtain z1 and b1 where "\<tau>\<^sub>1 = \<lbrace> z1 : b1  | CE_val (V_var z1)  ==  (CE_fst [v]\<^sup>c\<^sup>e)  \<rbrace>" using infer_v_form AE_fst by auto

  obtain xx :: x and bb :: b and xxa :: x and bba :: b and cc :: c where
       f1: "\<tau>\<^sub>2 = \<lbrace> xx : bb | CE_val (V_var xx) == CE_fst [v]\<^sup>c\<^sup>e \<rbrace> \<and> \<Theta> ; \<B> ; GNil\<turnstile>\<^sub>w\<^sub>f \<Delta> \<and> \<Theta> ; \<B> ; GNil \<turnstile> v \<Rightarrow> \<lbrace> xxa : B_pair bb bba | cc \<rbrace> \<and> atom xx \<sharp> v"
    using infer_e_elims(8)[OF AE_fst(2)] by metis
  obtain xxb :: x and bbb :: b and xxc :: x and bbc :: b and cca :: c where
     f2: "\<tau>\<^sub>1 = \<lbrace> xxb : bbb | CE_val (V_var xxb) == CE_fst [v]\<^sup>c\<^sup>e \<rbrace> \<and> \<Theta> ; \<B> ; GNil\<turnstile>\<^sub>w\<^sub>f \<Delta> \<and> \<Theta> ; \<B> ; GNil \<turnstile> v \<Rightarrow> \<lbrace> xxc : B_pair bbb bbc | cca \<rbrace> \<and> atom xxb \<sharp> v"
   using infer_e_elims(8)[OF AE_fst(1)] by metis
  then have "B_pair bb bba = B_pair bbb bbc"
    using f1 by (metis (no_types) b_of.simps infer_v_uniqueness) 
  then have "\<lbrace> xx : bbb | CE_val (V_var xx) == CE_fst [v]\<^sup>c\<^sup>e \<rbrace> = \<tau>\<^sub>2"
    using f1 by auto 
  then show ?thesis
  using f2 by (meson ce.fresh fresh_GNil type_e_eq wfG_x_fresh_in_v_simple) 
next
  case (AE_snd v)
  obtain xx :: x and bb :: b and xxa :: x and bba :: b and cc :: c where
       f1: "\<tau>\<^sub>2 = \<lbrace> xx : bba | CE_val (V_var xx) == CE_snd [v]\<^sup>c\<^sup>e \<rbrace> \<and> \<Theta> ; \<B> ; GNil\<turnstile>\<^sub>w\<^sub>f \<Delta> \<and> \<Theta> ; \<B> ; GNil \<turnstile> v \<Rightarrow> \<lbrace> xxa : B_pair bb bba | cc \<rbrace> \<and> atom xx \<sharp> v"
    using infer_e_elims(9)[OF AE_snd(2)] by metis
  obtain xxb :: x and bbb :: b and xxc :: x and bbc :: b and cca :: c where
     f2: "\<tau>\<^sub>1 = \<lbrace> xxb : bbc | CE_val (V_var xxb) == CE_snd [v]\<^sup>c\<^sup>e \<rbrace> \<and> \<Theta> ; \<B> ; GNil\<turnstile>\<^sub>w\<^sub>f \<Delta> \<and> \<Theta> ; \<B> ; GNil \<turnstile> v \<Rightarrow> \<lbrace> xxc : B_pair bbb bbc | cca \<rbrace> \<and> atom xxb \<sharp> v"
   using infer_e_elims(9)[OF AE_snd(1)] by metis
  then have "B_pair bb bba = B_pair bbb bbc"
    using f1 by (metis (no_types) b_of.simps infer_v_uniqueness) 
  then have "\<lbrace> xx : bbc | CE_val (V_var xx) == CE_snd [v]\<^sup>c\<^sup>e \<rbrace> = \<tau>\<^sub>2"
    using f1 by auto 
  then show ?thesis
  using f2 by (meson ce.fresh fresh_GNil type_e_eq wfG_x_fresh_in_v_simple) 
next
  case (AE_mvar x)
  then show ?case using infer_e_elims(10)[OF AE_mvar(1)] infer_e_elims(10)[OF AE_mvar(2)] wfD_unique   by metis
next
  case (AE_len x)
   then show ?case using infer_e_elims(16)[OF AE_len(1)] infer_e_elims(16)[OF AE_len(2)] by force
next
  case (AE_split x1a x2)
  then show ?case using infer_e_elims(22)[OF AE_split(1)] infer_e_elims(22)[OF AE_split(2)] by force
qed


section \<open>Statements\<close>

method subst_mth = (metis  subst_g_inside  infer_e_wf infer_v_wf infer_v_wf)

lemma subst_infer_check_v1:
  fixes v::v and v'::v and \<Gamma>::\<Gamma>
  assumes "\<Gamma> = \<Gamma>\<^sub>1@((x,b\<^sub>1,c0[z0::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>\<^sub>2)"  and 
          "\<Theta> ; \<B> ; \<Gamma>\<^sub>2 \<turnstile> v \<Rightarrow> \<tau>\<^sub>1"  and
          "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v' \<Leftarrow> \<tau>\<^sub>2"  and
          "\<Theta> ; \<B> ; \<Gamma>\<^sub>2 \<turnstile> \<tau>\<^sub>1 \<lesssim>  \<lbrace> z0 : b\<^sub>1 | c0 \<rbrace>" and "atom z0 \<sharp> (x,v)"
        shows "\<Theta> ; \<B>  ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v \<turnstile>  v'[x::=v]\<^sub>v\<^sub>v \<Leftarrow> \<tau>\<^sub>2[x::=v]\<^sub>\<tau>\<^sub>v"
  using  subst_g_inside check_v_wf assms subst_infer_check_v by metis

method subst_tuple_mth uses add = (
        (unfold fresh_prodN), (simp add: add  )+,
        (rule,metis fresh_z_subst_g add fresh_Pair ),
        (metis fresh_subst_dv add fresh_Pair ) )

thm subst_valid_simple

lemma infer_v_c_valid:
  assumes " \<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<tau>"  and   "\<Theta> ; \<B> ; \<Gamma>  \<turnstile> \<tau> \<lesssim> \<lbrace> z : b  | c \<rbrace>"
  shows  \<open>\<Theta> ; \<B> ; \<Gamma>  \<Turnstile> c[z::=v]\<^sub>c\<^sub>v \<close>
proof -
  obtain z1 and b1 and c1 where *:"\<tau> = \<lbrace> z1 : b1 | c1 \<rbrace> \<and> atom z1 \<sharp> (c,v,\<Gamma>)" using obtain_fresh_z by metis
  then have "b1 = b" using assms subtype_eq_base by metis
  moreover then have "\<Theta> ; \<B> ; \<Gamma> \<turnstile> v \<Rightarrow> \<lbrace> z1 : b | c1 \<rbrace>" using assms * by auto

  moreover have "\<Theta> ; \<B> ; (z1, b, c1) #\<^sub>\<Gamma> \<Gamma>  \<Turnstile> c[z::=[ z1 ]\<^sup>v]\<^sub>c\<^sub>v " proof -
    have "\<Theta> ; \<B> ; (z1, b, c1[z1::=[ z1 ]\<^sup>v]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<Turnstile> c[z::=[ z1 ]\<^sup>v]\<^sub>v "
      using subtype_valid[OF assms(2), of z1 z1 b c1 z c ] * fresh_prodN \<open>b1 = b\<close> by metis
    moreover have "c1[z1::=[ z1 ]\<^sup>v]\<^sub>v = c1" using subst_v_v_def by simp
    ultimately show ?thesis using subst_v_c_def by metis
  qed
  ultimately show ?thesis using * fresh_prodN subst_valid_simple by metis
qed

  

text \<open> Substitution Lemma for Statements \<close>
lemma subst_infer_check_s:
  fixes v::v and s::s and cs::branch_s and x::x and c::c and b::b and 
        \<Gamma>\<^sub>1::\<Gamma> and \<Gamma>\<^sub>2::\<Gamma> and css::branch_list
  assumes "\<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile> v \<Rightarrow> \<tau>"  and "\<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile> \<tau> \<lesssim> \<lbrace> z : b | c \<rbrace>"  and
          "atom z \<sharp> (x, v)"
  shows  "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>; \<Delta>  \<turnstile> s \<Leftarrow>  \<tau>'   \<Longrightarrow> 
          \<Gamma> = (\<Gamma>\<^sub>2@((x,b,c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>\<^sub>1)) \<Longrightarrow> 
          \<Theta> ; \<Phi> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<turnstile> s[x::=v]\<^sub>s\<^sub>v  \<Leftarrow> \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v" 
         and 
         "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>; \<Delta>; tid ; cons ; const ; v' \<turnstile> cs \<Leftarrow> \<tau>' \<Longrightarrow> 
          \<Gamma> = (\<Gamma>\<^sub>2@((x,b,c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>\<^sub>1)) \<Longrightarrow> 
          \<Theta> ; \<Phi> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v; 
          tid ; cons ; const ; v'[x::=v]\<^sub>v\<^sub>v \<turnstile> cs[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v" 
         and
         "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>; \<Delta>; tid ; dclist ; v' \<turnstile> css \<Leftarrow> \<tau>' \<Longrightarrow> 
         \<Gamma> = (\<Gamma>\<^sub>2@((x,b,c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>\<^sub>1)) \<Longrightarrow> 
         \<Theta> ; \<Phi> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v; tid ; dclist ; v'[x::=v]\<^sub>v\<^sub>v \<turnstile> 
             subst_branchlv css x v  \<Leftarrow> \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v"
  
using assms proof(nominal_induct \<tau>' and \<tau>' and \<tau>' avoiding: x v arbitrary: \<Gamma>\<^sub>2 and \<Gamma>\<^sub>2  and \<Gamma>\<^sub>2 
rule: check_s_check_branch_s_check_branch_list.strong_induct)
  case (check_valI \<Theta>  \<B> \<Gamma> \<Delta>  \<Phi>  v' \<tau>' \<tau>'')

  have sg: " \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v = \<Gamma>\<^sub>2[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>\<^sub>1" using  check_valI  by subst_mth
  thm wf_subst(12)
  have "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> (AS_val (v'[x::=v]\<^sub>v\<^sub>v)) \<Leftarrow> \<tau>''[x::=v]\<^sub>\<tau>\<^sub>v" proof
    have "\<Theta> ; \<B> ; \<Gamma>\<^sub>1\<turnstile>\<^sub>w\<^sub>f v : b " using infer_v_v_wf subtype_eq_base2 b_of.simps check_valI by metis
    thus  \<open>\<Theta> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v\<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v\<close>  using wf_subst(15) check_valI by auto
    show \<open> \<Theta>\<turnstile>\<^sub>w\<^sub>f \<Phi> \<close> using check_valI by auto
    show \<open> \<Theta> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Rightarrow> \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v\<close> proof(subst sg, rule subst_infer_v)
      show "\<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile> v \<Rightarrow> \<tau>" using check_valI by auto
      show "\<Theta> ; \<B> ; \<Gamma>\<^sub>2 @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1 \<turnstile> v' \<Rightarrow> \<tau>'"  using check_valI by metis
      show "\<Theta> ; \<B> ; \<Gamma>\<^sub>1  \<turnstile> \<tau> \<lesssim> \<lbrace> z: b   | c \<rbrace>" using check_valI by auto
      show "atom z \<sharp> (x, v)" using check_valI by auto
    qed
    show \<open>\<Theta> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v  \<turnstile>  \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v \<lesssim> \<tau>''[x::=v]\<^sub>\<tau>\<^sub>v\<close> using subst_subtype_tau check_valI sg by metis
  qed

  thus  ?case using Typing.check_valI subst_sv.simps sg by auto
next
  case (check_letI xa \<Theta> \<Phi> \<B> \<Gamma> \<Delta> ea \<tau>a za sa ba ca)
  have *:"(AS_let xa ea sa)[x::=v]\<^sub>s\<^sub>v=(AS_let xa (ea[x::=v]\<^sub>e\<^sub>v) sa[x::=v]\<^sub>s\<^sub>v)" 
    using subst_sv.simps \<open> atom xa \<sharp> x\<close>  \<open> atom xa \<sharp> v\<close> by auto
  show ?case unfolding * proof
    
    show "atom xa \<sharp> (\<Theta>,\<Phi>,\<B>,\<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v,\<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v,ea[x::=v]\<^sub>e\<^sub>v,\<tau>a[x::=v]\<^sub>\<tau>\<^sub>v)"
     by(subst_tuple_mth add: check_letI)

    show  "atom za \<sharp> (xa,\<Theta>,\<Phi>,\<B>,\<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v, \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v,ea[x::=v]\<^sub>e\<^sub>v,
                         \<tau>a[x::=v]\<^sub>\<tau>\<^sub>v,sa[x::=v]\<^sub>s\<^sub>v)"
      by(subst_tuple_mth add: check_letI)

    show "\<Theta>; \<Phi>; \<B>; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<turnstile> 
                          ea[x::=v]\<^sub>e\<^sub>v \<Rightarrow>  \<lbrace> za : ba | ca[x::=v]\<^sub>c\<^sub>v \<rbrace>" 
    proof - 
      have "\<Theta>; \<Phi>; \<B>; \<Gamma>\<^sub>2[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<^sub>1; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<turnstile> 
                          ea[x::=v]\<^sub>e\<^sub>v \<Rightarrow> \<lbrace> za : ba | ca \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v" 
        using check_letI subst_infer_e by metis
      thus ?thesis using check_letI subst_tv.simps 
        by (metis fresh_prod2I infer_e_wf subst_g_inside_simple)
    qed

    show  "\<Theta>; \<Phi>; \<B>; (xa, ba, ca[x::=v]\<^sub>c\<^sub>v[za::=V_var xa]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v;
                          \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> sa[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<tau>a[x::=v]\<^sub>\<tau>\<^sub>v" 
    proof -   
      have "\<Theta>; \<Phi>; \<B>; ((xa, ba, ca[za::=V_var xa]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)[x::=v]\<^sub>\<Gamma>\<^sub>v ; 
                          \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile>  sa[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<tau>a[x::=v]\<^sub>\<tau>\<^sub>v" 
        apply(rule check_letI(23)[of "(xa, ba, ca[za::=V_var xa]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>2"])
        by(metis check_letI append_g.simps subst_defs)+

      moreover have "(xa, ba, ca[x::=v]\<^sub>c\<^sub>v[za::=V_var xa]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v = 
                     ((xa, ba, ca[za::=V_var xa]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)[x::=v]\<^sub>\<Gamma>\<^sub>v" 
        using subst_cv_commute subst_gv.simps check_letI 
        by (metis ms_fresh_all(39) ms_fresh_all(49) subst_cv_commute_subst)
      ultimately show ?thesis 
        using subst_defs by  auto      
    qed
  qed
next
  case (check_assertI xa \<Theta> \<Phi> \<B> \<Gamma> \<Delta> ca \<tau> s)
  show ?case unfolding subst_sv.simps proof  
    show \<open>atom xa \<sharp> (\<Theta>, \<Phi>, \<B>, \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v, \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v, ca[x::=v]\<^sub>c\<^sub>v, \<tau>[x::=v]\<^sub>\<tau>\<^sub>v, s[x::=v]\<^sub>s\<^sub>v)\<close> 
       by(subst_tuple_mth add: check_assertI)
    have "xa \<noteq> x" using check_assertI by fastforce
    thus \<open> \<Theta> ; \<Phi> ; \<B> ; (xa, B_bool, ca[x::=v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> s[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<tau>[x::=v]\<^sub>\<tau>\<^sub>v\<close> 
      using check_assertI(12)[of "(xa, B_bool, c) #\<^sub>\<Gamma> \<Gamma>\<^sub>2" x v]  check_assertI subst_gv.simps append_g.simps by metis
    have \<open>\<Theta> ; \<B> ; \<Gamma>\<^sub>2[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<^sub>1  \<Turnstile> ca[x::=v]\<^sub>c\<^sub>v \<close> proof(rule  subst_valid )
      show   \<open>\<Theta> ; \<B> ; \<Gamma>\<^sub>1  \<Turnstile> c[z::=v]\<^sub>c\<^sub>v \<close> using infer_v_c_valid check_assertI by metis
      show \<open> \<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile>\<^sub>w\<^sub>f v : b \<close> using check_assertI infer_v_wf b_of.simps subtype_eq_base 
        by (metis subtype_eq_base2)
      show \<open> \<Theta> ; \<B>  \<turnstile>\<^sub>w\<^sub>f \<Gamma>\<^sub>1 \<close> using check_assertI infer_v_wf by metis
      have " \<Theta> ; \<B>  \<turnstile>\<^sub>w\<^sub>f \<Gamma>\<^sub>2 @ (x, b, c[z::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1" using check_assertI wfX_wfY by metis
      thus  \<open>atom x \<sharp> \<Gamma>\<^sub>1\<close> using check_assertI wfG_suffix wfG_elims by metis    

      moreover have "\<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile>\<^sub>w\<^sub>f  \<lbrace> z : b  | c \<rbrace>" using subtype_wfT check_assertI by metis

     (* hence "atom x \<notin> atom_dom \<Gamma>\<^sub>1" using wfG_x_fresh check_assertI infer_v_wf by metis
      moreover have " \<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile>\<^sub>w\<^sub>f c" using check_assertI *)
      moreover have "x \<noteq> z" using fresh_Pair check_assertI fresh_x_neq by metis
      ultimately show  \<open>atom x \<sharp> c\<close> using check_assertI wfT_fresh_c by metis
      
      show \<open> \<Theta> ; \<B>  \<turnstile>\<^sub>w\<^sub>f \<Gamma>\<^sub>2 @ (x, b, c[z::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1 \<close> using check_assertI wfX_wfY by metis
      show \<open>\<Theta> ; \<B> ; \<Gamma>\<^sub>2 @ (x, b, c[z::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1  \<Turnstile> ca \<close> using check_assertI by auto
    qed
    thus  \<open>\<Theta> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v  \<Turnstile> ca[x::=v]\<^sub>c\<^sub>v \<close> using check_assertI 
    proof -
      show ?thesis
        by (metis (no_types) \<open>\<Gamma> = \<Gamma>\<^sub>2 @ (x, b, c[z::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1\<close> \<open>\<Theta> ; \<B> ; \<Gamma> \<Turnstile> ca\<close> \<open>\<Theta> ; \<B> ; \<Gamma>\<^sub>2[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<^sub>1 \<Turnstile> ca[x::=v]\<^sub>c\<^sub>v\<close> subst_g_inside valid_g_wf) (* 93 ms *)
    qed

    have "\<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile>\<^sub>w\<^sub>f v : b" using infer_v_wf b_of.simps check_assertI 
      by (metis subtype_eq_base2)
    thus  \<open> \<Theta> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v \<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<close> using wf_subst2(6) check_assertI by metis
  qed
next
  case (check_branch_list_consI \<Theta> \<Phi> \<B> \<Gamma> \<Delta> tid dclist vv cs \<tau> css)  
  show ?case unfolding * using subst_sv.simps check_branch_list_consI by simp
next
  case (check_branch_list_finalI \<Theta> \<Phi> \<B> \<Gamma> \<Delta> tid dclist v cs \<tau>)
  show ?case unfolding * using subst_sv.simps check_branch_list_finalI by simp
next
 case (check_branch_s_branchI \<Theta> \<B> \<Gamma> \<Delta> \<tau> const xa \<Phi> tid cons va sa)
 hence *:"(AS_branch cons xa sa)[x::=v]\<^sub>s\<^sub>v = (AS_branch cons xa sa[x::=v]\<^sub>s\<^sub>v)" using subst_branchv.simps fresh_Pair by metis
 show ?case unfolding *  proof

    show "\<Theta> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v\<turnstile>\<^sub>w\<^sub>f \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v "   
      using wf_subst check_branch_s_branchI subtype_eq_base2 b_of.simps infer_v_wf by metis 
 
    show  "\<turnstile>\<^sub>w\<^sub>f \<Theta> " using check_branch_s_branchI by metis

    show  "\<Theta> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v  \<turnstile>\<^sub>w\<^sub>f \<tau>[x::=v]\<^sub>\<tau>\<^sub>v " 
      using wf_subst check_branch_s_branchI subtype_eq_base2 b_of.simps infer_v_wf by metis 
 
    show wft:"\<Theta> ; {||} ; GNil\<turnstile>\<^sub>w\<^sub>f const "  using check_branch_s_branchI by metis

    show "atom xa \<sharp> (\<Theta>, \<Phi>, \<B>, \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v, \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v, tid, cons, const,va[x::=v]\<^sub>v\<^sub>v, \<tau>[x::=v]\<^sub>\<tau>\<^sub>v)"
        apply(unfold fresh_prodN, (simp add: check_branch_s_branchI )+)
        apply(rule,metis fresh_z_subst_g check_branch_s_branchI fresh_Pair )
      by(metis fresh_subst_dv check_branch_s_branchI fresh_Pair )  

    have "\<Theta> ; \<Phi> ; \<B> ; ((xa, b_of const, CE_val va  ==  CE_val(V_cons tid cons (V_var xa))   AND c_of const xa) #\<^sub>\<Gamma> \<Gamma>)[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> sa[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<tau>[x::=v]\<^sub>\<tau>\<^sub>v" 
      using check_branch_s_branchI   by (metis append_g.simps(2))

    moreover have "(xa, b_of const, CE_val va[x::=v]\<^sub>v\<^sub>v  ==  CE_val (V_cons tid cons (V_var xa))   AND c_of (const) xa) #\<^sub>\<Gamma> \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v = 
                  ((xa, b_of const , CE_val va  ==  CE_val (V_cons tid cons (V_var xa)) AND c_of const xa) #\<^sub>\<Gamma> \<Gamma>)[x::=v]\<^sub>\<Gamma>\<^sub>v" 
    proof -
      have *:"xa \<noteq> x" using check_branch_s_branchI fresh_at_base by metis
      have "atom x \<sharp> const" using wfT_nil_supp[OF wft]  fresh_def by auto
      hence "atom x \<sharp> (const,xa)" using fresh_at_base wfT_nil_supp[OF wft] fresh_Pair fresh_def * by auto
      moreover hence "(c_of (const) xa)[x::=v]\<^sub>c\<^sub>v =  c_of (const) xa"  
        using c_of_fresh[of x const xa] forget_subst_cv wfT_nil_supp wft by metis
      moreover hence "(V_cons tid cons (V_var xa))[x::=v]\<^sub>v\<^sub>v  = (V_cons tid cons (V_var xa))" using check_branch_s_branchI subst_vv.simps * by metis    
      ultimately show ?thesis using subst_gv.simps check_branch_s_branchI subst_cv.simps subst_cev.simps *  by presburger
    qed

    ultimately show  "\<Theta> ; \<Phi> ; \<B> ; (xa, b_of const, CE_val va[x::=v]\<^sub>v\<^sub>v  ==  CE_val (V_cons tid cons (V_var xa))  AND  c_of const xa) #\<^sub>\<Gamma> \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> sa[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<tau>[x::=v]\<^sub>\<tau>\<^sub>v" 
      by metis
  qed

next
  case (check_let2I xa \<Theta> \<Phi> \<B> G \<Delta> t s1 \<tau>a s2 )
  hence *:"(AS_let2 xa t s1 s2)[x::=v]\<^sub>s\<^sub>v = (AS_let2 xa t[x::=v]\<^sub>\<tau>\<^sub>v  (s1[x::=v]\<^sub>s\<^sub>v) s2[x::=v]\<^sub>s\<^sub>v)" using subst_sv.simps fresh_Pair by metis
  have "xa \<noteq> x"  using check_let2I fresh_at_base by metis
  show ?case unfolding * proof
    show "atom xa \<sharp> (\<Theta>, \<Phi>, \<B>, G[x::=v]\<^sub>\<Gamma>\<^sub>v, \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v, t[x::=v]\<^sub>\<tau>\<^sub>v, s1[x::=v]\<^sub>s\<^sub>v, \<tau>a[x::=v]\<^sub>\<tau>\<^sub>v)" 
       by(subst_tuple_mth add: check_let2I)    
    show "\<Theta> ; \<Phi> ; \<B> ; G[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> s1[x::=v]\<^sub>s\<^sub>v \<Leftarrow> t[x::=v]\<^sub>\<tau>\<^sub>v" using check_let2I by metis
  
    have "\<Theta> ; \<Phi> ; \<B> ; ((xa, b_of t, c_of t xa) #\<^sub>\<Gamma> G)[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> s2[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<tau>a[x::=v]\<^sub>\<tau>\<^sub>v" 
    proof(rule check_let2I(14))
      show \<open>(xa, b_of t, c_of t xa) #\<^sub>\<Gamma> G = (((xa, b_of t, c_of t xa)#\<^sub>\<Gamma> \<Gamma>\<^sub>2)) @ (x, b, c[z::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1\<close> 
        using check_let2I append_g.simps by metis
      show \<open> \<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile> v \<Rightarrow> \<tau>\<close> using check_let2I by metis
      show \<open>\<Theta> ; \<B> ; \<Gamma>\<^sub>1  \<turnstile> \<tau> \<lesssim> \<lbrace> z : b  | c \<rbrace>\<close> using check_let2I by metis
      show \<open>atom z \<sharp> (x, v)\<close> using check_let2I by metis
    qed
    moreover  have "c_of t[x::=v]\<^sub>\<tau>\<^sub>v xa = (c_of t xa)[x::=v]\<^sub>c\<^sub>v" using subst_v_c_of fresh_Pair check_let2I by metis
    moreover have "b_of t[x::=v]\<^sub>\<tau>\<^sub>v = b_of t" using b_of.simps subst_tv.simps b_of_subst by metis
    ultimately show " \<Theta> ; \<Phi> ; \<B> ; (xa, b_of t[x::=v]\<^sub>\<tau>\<^sub>v, c_of t[x::=v]\<^sub>\<tau>\<^sub>v xa) #\<^sub>\<Gamma> G[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> s2[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<tau>a[x::=v]\<^sub>\<tau>\<^sub>v" 
      using check_let2I(14) subst_gv.simps \<open>xa \<noteq> x\<close> b_of.simps by metis
  qed
 
next

  case (check_varI u \<Theta> \<Phi> \<B> \<Gamma> \<Delta> \<tau>' va \<tau>'' s)
  have **: "\<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v = \<Gamma>\<^sub>2[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>\<^sub>1" using subst_g_inside check_s_wf check_varI by meson

  have "\<Theta> ; \<Phi>  ;\<B> ; subst_gv \<Gamma> x v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v \<turnstile> AS_var u \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v (va[x::=v]\<^sub>v\<^sub>v) (subst_sv s x v) \<Leftarrow> \<tau>''[x::=v]\<^sub>\<tau>\<^sub>v" 
  proof(rule Typing.check_varI)
    show "atom u \<sharp> (\<Theta>, \<Phi>, \<B>, \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v, \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v, \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v, va[x::=v]\<^sub>v\<^sub>v, \<tau>''[x::=v]\<^sub>\<tau>\<^sub>v)" 
      by(subst_tuple_mth add: check_varI)    
    show "\<Theta> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v  \<turnstile> va[x::=v]\<^sub>v\<^sub>v \<Leftarrow> \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v" using check_varI subst_infer_check_v ** by metis
    show "\<Theta> ; \<Phi> ; \<B> ; subst_gv \<Gamma> x v ; (u, \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v) #\<^sub>\<Delta> \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> s[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<tau>''[x::=v]\<^sub>\<tau>\<^sub>v" proof - 
      have "wfD \<Theta> \<B> (\<Gamma>\<^sub>2 @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1) ((u,\<tau>')#\<^sub>\<Delta> \<Delta>)" using check_varI check_s_wf  by meson
      moreover have "wfV \<Theta> \<B> \<Gamma>\<^sub>1 v (b_of \<tau>)"  using infer_v_wf check_varI(6) check_varI by metis
      have "wfD \<Theta> \<B> (\<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v) ((u, \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v) #\<^sub>\<Delta> \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v)" proof(subst subst_dv.simps(2)[symmetric], subst **, rule wfD_subst)
        show "\<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile> v \<Rightarrow> \<tau>" using check_varI by auto
        show "\<Theta> ; \<B> ; \<Gamma>\<^sub>2 @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1\<turnstile>\<^sub>w\<^sub>f (u, \<tau>') #\<^sub>\<Delta> \<Delta>" using check_varI check_s_wf by simp
        show "b_of \<tau> = b" using check_varI subtype_eq_base2 b_of.simps by auto
      qed
      thus ?thesis using  check_varI by auto
    qed
  qed
  moreover have "atom u \<sharp> (x,v)" using u_fresh_xv by auto
  ultimately show ?case using subst_sv.simps(7) by auto

next
  case (check_assignI P \<Phi> \<B> \<Gamma> \<Delta> u \<tau>1  v' z1 \<tau>')  (* may need to revisit subst in \<Delta> as well *)

 have "wfG P \<B> \<Gamma>" using check_v_wf check_assignI by simp
 hence gs: "\<Gamma>\<^sub>2[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<^sub>1 = \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v" using subst_g_inside check_assignI by simp

  have "P ; \<Phi> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v  ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> AS_assign u (v'[x::=v]\<^sub>v\<^sub>v) \<Leftarrow> \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v"
  proof(rule Typing.check_assignI)
    show "P \<turnstile>\<^sub>w\<^sub>f \<Phi> " using check_assignI by auto
    show "wfD P \<B> (\<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v) \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v" using wf_subst(15)[OF check_assignI(2)] gs infer_v_v_wf check_assignI b_of.simps subtype_eq_base2 by metis
    thus "(u, \<tau>1[x::=v]\<^sub>\<tau>\<^sub>v) \<in> setD \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v" using check_assignI  subst_dv_member by metis
    thus  "P ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Leftarrow> \<tau>1[x::=v]\<^sub>\<tau>\<^sub>v" using subst_infer_check_v check_assignI gs by metis

    have "P ; \<B> ; \<Gamma>\<^sub>2[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<^sub>1  \<turnstile> \<lbrace> z : B_unit  | TRUE \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v \<lesssim> \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v" proof(rule subst_subtype_tau)
      show "P ; \<B> ; \<Gamma>\<^sub>1  \<turnstile> v \<Rightarrow> \<tau>" using check_assignI by auto
      show "P ; \<B> ; \<Gamma>\<^sub>1  \<turnstile> \<tau> \<lesssim> \<lbrace> z : b  | c \<rbrace>" using check_assignI by meson
      show "P ; \<B> ; \<Gamma>\<^sub>2 @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1  \<turnstile> \<lbrace> z : B_unit  | TRUE \<rbrace> \<lesssim> \<tau>'" using check_assignI
        by (metis Abs1_eq_iff(3) \<tau>.eq_iff c.fresh(1) c.perm_simps(1))
      show "atom z \<sharp> (x, v)" using check_assignI by auto
    qed
    moreover have "\<lbrace> z : B_unit  | TRUE \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v = \<lbrace> z : B_unit  | TRUE \<rbrace>" using subst_tv.simps subst_cv.simps check_assignI by presburger
    ultimately show   "P ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v  \<turnstile> \<lbrace> z : B_unit  | TRUE \<rbrace> \<lesssim> \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v" using gs by auto
  qed
  thus ?case using subst_sv.simps(5) by auto
  
next
  case (check_whileI \<Theta> \<Phi> \<B> \<Gamma> \<Delta> s1 z' s2 \<tau>')
  have " wfG \<Theta> \<B> (\<Gamma>\<^sub>2 @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1)" using check_whileI check_s_wf by meson
  hence **: " \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v = \<Gamma>\<^sub>2[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>\<^sub>1" using subst_g_inside wf check_whileI  by auto
  have teq: "(\<lbrace> z : B_unit  | TRUE \<rbrace>)[x::=v]\<^sub>\<tau>\<^sub>v = (\<lbrace> z : B_unit  | TRUE \<rbrace>)"  by(auto simp add: subst_sv.simps check_whileI)
  moreover have "(\<lbrace> z : B_unit  | TRUE \<rbrace>) = (\<lbrace> z' : B_unit  | TRUE \<rbrace>)" using type_eq_flip c.fresh flip_fresh_fresh by metis
  ultimately have  teq2:"(\<lbrace> z' : B_unit  | TRUE \<rbrace>)[x::=v]\<^sub>\<tau>\<^sub>v = (\<lbrace> z' : B_unit  | TRUE \<rbrace>)" by metis

  hence "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> s1[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<lbrace> z' : B_bool  | TRUE \<rbrace>" using check_whileI  subst_sv.simps subst_top_eq by metis
  moreover have "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> s2[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<lbrace> z' : B_unit  | TRUE \<rbrace>" using check_whileI subst_top_eq by metis
  moreover have "\<Theta> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v  \<turnstile> \<lbrace> z' : B_unit  | TRUE \<rbrace> \<lesssim> \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v" proof -
    have "\<Theta> ; \<B> ; \<Gamma>\<^sub>2[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<^sub>1  \<turnstile> \<lbrace> z' : B_unit  | TRUE \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v \<lesssim> \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v" proof(rule subst_subtype_tau)
      show "\<Theta> ; \<B> ; \<Gamma>\<^sub>1  \<turnstile> v \<Rightarrow> \<tau>" by(auto simp add: check_whileI)
      show "\<Theta> ; \<B> ; \<Gamma>\<^sub>1  \<turnstile> \<tau> \<lesssim> \<lbrace> z : b  | c \<rbrace>"  by(auto simp add: check_whileI)
      show "\<Theta> ; \<B> ; \<Gamma>\<^sub>2 @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1  \<turnstile> \<lbrace> z' : B_unit  | TRUE \<rbrace> \<lesssim> \<tau>'"  using check_whileI by metis
      show "atom z \<sharp> (x, v)" by(auto simp add: check_whileI)
    qed
    thus ?thesis using teq2 ** by auto
  qed

  ultimately have  " \<Theta> ; \<Phi> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> AS_while s1[x::=v]\<^sub>s\<^sub>v s2[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v" 
   using Typing.check_whileI  by metis
  then show ?case  using subst_sv.simps by metis
next
  case (check_seqI P \<Phi> \<B> \<Gamma> \<Delta>   s1 z s2 \<tau> ) 
  hence "P ; \<Phi>; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ;  \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v   \<turnstile> AS_seq (s1[x::=v]\<^sub>s\<^sub>v) (s2[x::=v]\<^sub>s\<^sub>v)  \<Leftarrow> \<tau>[x::=v]\<^sub>\<tau>\<^sub>v" using Typing.check_seqI subst_top_eq check_seqI by metis
  then show ?case using subst_sv.simps by metis
next
  case (check_caseI \<Theta> \<Phi> \<B> \<Gamma> \<Delta> tid dclist v' cs \<tau>  za)

  have wf: "wfG \<Theta> \<B> \<Gamma>" using check_caseI  check_v_wf  by simp
  have **: "\<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v = \<Gamma>\<^sub>2[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>\<^sub>1" using subst_g_inside wf check_caseI by auto
  
  have "\<Theta> ; \<Phi> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> AS_match (v'[x::=v]\<^sub>v\<^sub>v) (subst_branchlv cs x v) \<Leftarrow> \<tau>[x::=v]\<^sub>\<tau>\<^sub>v" proof(rule  Typing.check_caseI )
    show "check_branch_list \<Theta> \<Phi> \<B> (\<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v) \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v tid dclist v'[x::=v]\<^sub>v\<^sub>v (subst_branchlv cs x v ) (\<tau>[x::=v]\<^sub>\<tau>\<^sub>v)"  using check_caseI by auto
    show "AF_typedef tid dclist \<in> set \<Theta>" using check_caseI by auto
    show "\<Theta> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Leftarrow> \<lbrace> za : B_id tid  | TRUE \<rbrace>" proof -
      have "\<Theta> ; \<B> ; \<Gamma>\<^sub>2 @ (x, b, c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1  \<turnstile> v' \<Leftarrow>  \<lbrace> za : B_id tid  | TRUE \<rbrace>"
        using check_caseI by argo
      hence "\<Theta> ; \<B> ; \<Gamma>\<^sub>2[x::=v]\<^sub>\<Gamma>\<^sub>v @ \<Gamma>\<^sub>1  \<turnstile> v'[x::=v]\<^sub>v\<^sub>v \<Leftarrow>  (\<lbrace> za : B_id tid  | TRUE \<rbrace>)[x::=v]\<^sub>\<tau>\<^sub>v" 
        using check_caseI subst_infer_check_v[OF check_caseI(7) _  check_caseI(8)  check_caseI(9)] by meson
      moreover have "(\<lbrace> za : B_id tid  | TRUE \<rbrace>) = ((\<lbrace> za : B_id tid  | TRUE \<rbrace>)[x::=v]\<^sub>\<tau>\<^sub>v)"  
        using subst_cv.simps subst_tv.simps subst_cv_true by fast
      ultimately show  ?thesis using check_caseI ** by argo
    qed
    show "wfTh \<Theta>" using check_caseI by auto
  qed
  thus ?case using subst_branchlv.simps subst_sv.simps(4) by metis
next
  case (check_ifI z' \<Theta> \<Phi> \<B> \<Gamma> \<Delta> va s1 s2 \<tau>')
  show ?case unfolding  subst_sv.simps proof
    show \<open>atom z' \<sharp> (\<Theta>, \<Phi>, \<B>, \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v, \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v, va[x::=v]\<^sub>v\<^sub>v, s1[x::=v]\<^sub>s\<^sub>v, s2[x::=v]\<^sub>s\<^sub>v, \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v)\<close> 
      by(subst_tuple_mth add: check_ifI)    
    have *:"\<lbrace> z' : B_bool  | TRUE \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v = \<lbrace> z' : B_bool  | TRUE \<rbrace>" using subst_tv.simps check_ifI 
      by (metis freshers(19) subst_cv.simps(1) type_eq_subst)
    have **: "\<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v = \<Gamma>\<^sub>2[x::=v]\<^sub>\<Gamma>\<^sub>v@\<Gamma>\<^sub>1" using subst_g_inside wf check_ifI check_v_wf by metis
    show   \<open>\<Theta> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v  \<turnstile> va[x::=v]\<^sub>v\<^sub>v \<Leftarrow> \<lbrace> z' : B_bool  | TRUE \<rbrace>\<close> 
    proof(subst *[symmetric], rule subst_infer_check_v1[where \<Gamma>\<^sub>1=\<Gamma>\<^sub>2 and \<Gamma>\<^sub>2=\<Gamma>\<^sub>1])
      show "\<Gamma> = \<Gamma>\<^sub>2 @ ((x, b ,c[z::=[ x ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> \<Gamma>\<^sub>1)" using check_ifI by metis
     show \<open> \<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile> v \<Rightarrow> \<tau>\<close> using check_ifI by metis
     show \<open>\<Theta> ; \<B> ; \<Gamma>  \<turnstile> va \<Leftarrow> \<lbrace> z' : B_bool  | TRUE \<rbrace>\<close> using check_ifI by metis
     show \<open>\<Theta> ; \<B> ; \<Gamma>\<^sub>1  \<turnstile> \<tau> \<lesssim> \<lbrace> z : b  | c \<rbrace>\<close> using check_ifI by metis
     show \<open>atom z \<sharp> (x, v)\<close> using check_ifI by metis
   qed

   have " \<lbrace> z' : b_of \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v  | [ va[x::=v]\<^sub>v\<^sub>v ]\<^sup>c\<^sup>e  ==  [ [ L_true ]\<^sup>v ]\<^sup>c\<^sup>e   IMP  c_of \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v z'  \<rbrace> = \<lbrace> z' : b_of \<tau>'  | [ va ]\<^sup>c\<^sup>e  ==  [ [ L_true ]\<^sup>v ]\<^sup>c\<^sup>e   IMP  c_of \<tau>' z'  \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v"
     by(simp add: subst_tv.simps fresh_Pair check_ifI b_of_subst subst_v_c_of)
    
   thus  \<open> \<Theta> ; \<Phi> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> s1[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<lbrace> z' : b_of \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v  | [ va[x::=v]\<^sub>v\<^sub>v ]\<^sup>c\<^sup>e  ==  [ [ L_true ]\<^sup>v ]\<^sup>c\<^sup>e   IMP  c_of \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v z'  \<rbrace>\<close>      
     using check_ifI by metis
   have " \<lbrace> z' : b_of \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v  | [ va[x::=v]\<^sub>v\<^sub>v ]\<^sup>c\<^sup>e  ==  [ [ L_false ]\<^sup>v ]\<^sup>c\<^sup>e   IMP  c_of \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v z'  \<rbrace> = \<lbrace> z' : b_of \<tau>'  | [ va ]\<^sup>c\<^sup>e  ==  [ [ L_false ]\<^sup>v ]\<^sup>c\<^sup>e   IMP  c_of \<tau>' z'  \<rbrace>[x::=v]\<^sub>\<tau>\<^sub>v"
     by(simp add: subst_tv.simps fresh_Pair check_ifI b_of_subst subst_v_c_of)
   thus \<open> \<Theta> ; \<Phi> ; \<B> ; \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v ; \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  \<turnstile> s2[x::=v]\<^sub>s\<^sub>v \<Leftarrow> \<lbrace> z' : b_of \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v  | [ va[x::=v]\<^sub>v\<^sub>v ]\<^sup>c\<^sup>e  ==  [ [ L_false ]\<^sup>v ]\<^sup>c\<^sup>e   IMP  c_of \<tau>'[x::=v]\<^sub>\<tau>\<^sub>v z'  \<rbrace>\<close> 
     using check_ifI by metis
  qed
qed

lemma subst_check_check_s:
  fixes v::v and s::s and cs::branch_s and x::x and c::c and b::b and \<Gamma>\<^sub>1::\<Gamma> and \<Gamma>\<^sub>2::\<Gamma>
  assumes "\<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile> v \<Leftarrow> \<lbrace> z : b | c \<rbrace>"  and  "atom z \<sharp> (x, v)"
    and  "check_s \<Theta> \<Phi> \<B> \<Gamma> \<Delta>  s  \<tau>'" and "\<Gamma>  = (\<Gamma>\<^sub>2@((x,b,c[z::=[x]\<^sup>v]\<^sub>c\<^sub>v)#\<^sub>\<Gamma>\<Gamma>\<^sub>1))" 
  shows "check_s \<Theta> \<Phi> \<B> (subst_gv \<Gamma> x v)    \<Delta>[x::=v]\<^sub>\<Delta>\<^sub>v  (s[x::=v]\<^sub>s\<^sub>v)  (subst_tv  \<tau>' x v )" 
proof -
  obtain \<tau> where  "\<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile> v \<Rightarrow> \<tau> \<and> \<Theta> ; \<B> ; \<Gamma>\<^sub>1 \<turnstile> \<tau> \<lesssim> \<lbrace> z : b | c \<rbrace>" using check_v_elims assms by auto
  thus ?thesis using subst_infer_check_s assms by metis
qed

text \<open> If a statement checks against a type @{text "\<tau>"} then it checks against a supertype of @{text "\<tau>"} \<close>
lemma check_s_supertype:
  fixes v::v and s::s and cs::branch_s and x::x and c::c and b::b and \<Gamma>::\<Gamma> and \<Gamma>'::\<Gamma> and css::branch_list
  shows  "check_s \<Theta> \<Phi> \<B> G \<Delta>  s  t1 \<Longrightarrow> \<Theta> ; \<B> ; G \<turnstile> t1 \<lesssim> t2  \<Longrightarrow> check_s \<Theta> \<Phi> \<B> G \<Delta>  s  t2"  and 
         "check_branch_s \<Theta> \<Phi> \<B> G \<Delta> tid cons const v cs t1 \<Longrightarrow> \<Theta> ; \<B> ; G \<turnstile> t1 \<lesssim> t2 \<Longrightarrow> check_branch_s \<Theta> \<Phi> \<B> G \<Delta> tid cons const v cs t2" and
         "check_branch_list \<Theta> \<Phi> \<B> G \<Delta> tid dclist v css t1 \<Longrightarrow> \<Theta> ; \<B> ; G \<turnstile> t1 \<lesssim> t2 \<Longrightarrow> check_branch_list \<Theta> \<Phi> \<B> G \<Delta> tid dclist v css t2"
proof(induct arbitrary: t2 and t2 and t2 rule: check_s_check_branch_s_check_branch_list.inducts)
  case (check_valI  \<Theta> \<B> \<Gamma> \<Delta>  \<Phi> v \<tau>' \<tau>  )
  hence " \<Theta> ; \<B> ; \<Gamma> \<turnstile> \<tau>' \<lesssim> t2" using subtype_trans by meson
  then show ?case using subtype_trans Typing.check_valI check_valI by metis
   
next
    case (check_letI x \<Theta> \<Phi> \<B> \<Gamma> \<Delta> e \<tau> z s b c)
  show ?case proof(rule Typing.check_letI)
    show "atom x \<sharp>(\<Theta>, \<Phi>, \<B>, \<Gamma>, \<Delta>, e, t2)" using check_letI subtype_fresh_tau fresh_prodN by metis
    thm subtype_fresh_tau
    show "atom z \<sharp> (x, \<Theta>, \<Phi>, \<B>, \<Gamma>, \<Delta>, e, t2, s)" using check_letI(2) subtype_fresh_tau[of z \<tau> \<Gamma> _ _ t2] fresh_prodN check_letI(6) by auto
    show "\<Theta> ; \<Phi> ; \<B> ; \<Gamma> ; \<Delta> \<turnstile> e \<Rightarrow> \<lbrace> z : b  | c \<rbrace>" using check_letI by meson

    have "wfG \<Theta> \<B> ((x, b, c[z::=[x]\<^sup>v]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" using check_letI check_s_wf subst_defs by metis
    moreover have "setG \<Gamma> \<subseteq> setG ((x, b, c[z::=[x]\<^sup>v]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>)" by auto
    ultimately have "  \<Theta> ; \<B> ; (x, b, c[z::=[x]\<^sup>v]\<^sub>v) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> \<tau> \<lesssim> t2" using subtype_weakening[OF check_letI(6)] by auto
    thus  "\<Theta> ; \<Phi> ; \<B> ; (x, b, c[z::=[x]\<^sup>v]\<^sub>v) #\<^sub>\<Gamma> \<Gamma> ; \<Delta>  \<turnstile> s \<Leftarrow> t2" using check_letI subst_defs by metis
  qed
next
   
next
  case (check_branch_list_consI \<Theta> \<Phi> \<B> \<Gamma> \<Delta> tid dclist v cs \<tau> css)
  then show ?case using  Typing.check_branch_list_consI by auto
next
  case (check_branch_list_finalI \<Theta> \<Phi> \<B> \<Gamma> \<Delta> tid dclist v cs \<tau>)
  then show ?case using  Typing.check_branch_list_finalI by auto
next
    case (check_branch_s_branchI \<Theta> \<B> \<Gamma> \<Delta> \<tau> const x \<Phi> tid cons v s)
    show  ?case proof
      have "atom x \<sharp> t2" using subtype_fresh_tau[of x \<tau> ] check_branch_s_branchI(5,8)   fresh_prodN by metis
      thus  "atom x \<sharp> (\<Theta>, \<Phi>, \<B>, \<Gamma>, \<Delta>, tid, cons, const, v, t2)" using check_branch_s_branchI  fresh_prodN by metis
      show  "wfT \<Theta> \<B> \<Gamma> t2" using subtype_wf check_branch_s_branchI by meson
      show  "\<Theta> ; \<Phi> ; \<B> ; (x, b_of const, CE_val v  ==  CE_val(V_cons tid cons (V_var x)) AND c_of const x) #\<^sub>\<Gamma> \<Gamma> ; \<Delta>  \<turnstile> s \<Leftarrow> t2" proof -
        have "wfG \<Theta> \<B> ((x, b_of const, CE_val v  ==  CE_val(V_cons tid cons (V_var x))   AND c_of const x) #\<^sub>\<Gamma> \<Gamma>)" using check_s_wf check_branch_s_branchI by metis
        moreover have "setG \<Gamma> \<subseteq> setG ((x, b_of const, CE_val v  ==  CE_val (V_cons tid cons (V_var x)) AND c_of const x) #\<^sub>\<Gamma> \<Gamma>)" by auto
        hence "\<Theta> ; \<B> ; ((x, b_of const, CE_val v  ==  CE_val(V_cons tid cons (V_var x)) AND c_of const x) #\<^sub>\<Gamma> \<Gamma>) \<turnstile> \<tau> \<lesssim> t2" 
          using check_branch_s_branchI subtype_weakening 
          using calculation by presburger
       thus ?thesis using check_branch_s_branchI by presburger
     qed
   qed(auto simp add: check_branch_s_branchI)


next
  case (check_ifI z \<Theta> \<Phi> \<B> \<Gamma> \<Delta> v s1 s2 \<tau>)
  show  ?case proof(rule Typing.check_ifI)
    have *:"atom z \<sharp> t2" using subtype_fresh_tau[of z \<tau> \<Gamma> ] check_ifI   fresh_prodN by auto
    thus \<open>atom z \<sharp> (\<Theta>, \<Phi>, \<B>, \<Gamma>, \<Delta>, v, s1, s2, t2)\<close> using check_ifI fresh_prodN by auto
    show \<open>\<Theta> ; \<B> ; \<Gamma>  \<turnstile> v \<Leftarrow> \<lbrace> z : B_bool  | TRUE \<rbrace>\<close> using check_ifI by auto
    show \<open> \<Theta> ; \<Phi> ; \<B> ; \<Gamma> ; \<Delta>  \<turnstile> s1 \<Leftarrow> \<lbrace> z : b_of t2  | [ v ]\<^sup>c\<^sup>e  ==  [ [ L_true ]\<^sup>v ]\<^sup>c\<^sup>e   IMP  c_of t2 z  \<rbrace>\<close> 
      using check_ifI subtype_if1 fresh_prodN base_for_lit.simps b_of.simps * check_v_wf by metis

    show \<open> \<Theta> ; \<Phi> ; \<B> ; \<Gamma> ; \<Delta>  \<turnstile> s2 \<Leftarrow> \<lbrace> z : b_of t2  | [ v ]\<^sup>c\<^sup>e  ==  [ [ L_false ]\<^sup>v ]\<^sup>c\<^sup>e   IMP  c_of t2 z  \<rbrace>\<close>
     using check_ifI subtype_if1 fresh_prodN base_for_lit.simps b_of.simps * check_v_wf by metis
  qed
next
  case (check_assertI x \<Theta> \<Phi> \<B> \<Gamma> \<Delta> c \<tau> s)
  thm  subtype_fresh_tau[where ?t1.0=\<tau> and ?x=x]
  show ?case proof
    have "atom x \<sharp> t2" using subtype_fresh_tau[OF _ _ \<open>\<Theta> ; \<B> ; \<Gamma>  \<turnstile> \<tau> \<lesssim> t2\<close>] check_assertI fresh_prodN by simp
    thus  "atom x \<sharp> (\<Theta>, \<Phi>, \<B>, \<Gamma>, \<Delta>, c, t2, s)"   using subtype_fresh_tau check_assertI   fresh_prodN by simp
    have "\<Theta> ; \<B> ; (x, B_bool, c) #\<^sub>\<Gamma> \<Gamma>  \<turnstile> \<tau> \<lesssim> t2" apply(rule subtype_weakening) 
      using check_assertI apply simp
      using setG.simps apply blast
      using check_assertI check_s_wf by simp
    thus  "\<Theta> ; \<Phi> ; \<B> ; (x, B_bool, c) #\<^sub>\<Gamma> \<Gamma> ; \<Delta>  \<turnstile> s \<Leftarrow> t2" using check_assertI by simp
    show "\<Theta> ; \<B> ; \<Gamma>  \<Turnstile> c " using check_assertI by auto
    show "\<Theta> ; \<B> ; \<Gamma> \<turnstile>\<^sub>w\<^sub>f \<Delta> " using check_assertI by auto
  qed
next
   case (check_let2I x P \<Phi> \<B> G \<Delta> t s1 \<tau> s2 )
  have "wfG P \<B> ((x, b_of t, c_of t x) #\<^sub>\<Gamma> G)" 
    using check_let2I check_s_wf by metis
  moreover have "setG G \<subseteq> setG ((x, b_of t, c_of t x) #\<^sub>\<Gamma> G)" by auto
  ultimately have  *:"P ; \<B> ; (x, b_of t, c_of t x) #\<^sub>\<Gamma> G  \<turnstile> \<tau> \<lesssim> t2" using check_let2I subtype_weakening by metis
  show  ?case proof(rule Typing.check_let2I)
    have "atom x \<sharp> t2" using subtype_fresh_tau[of x \<tau> ] check_let2I   fresh_prodN by metis  
    thus "atom x \<sharp> (P, \<Phi>, \<B>, G, \<Delta>, t, s1, t2)" using check_let2I  fresh_prodN by metis
    show "P ; \<Phi> ; \<B> ; G ; \<Delta>  \<turnstile> s1 \<Leftarrow> t"  using check_let2I by blast
    show "P ; \<Phi> ; \<B> ;(x, b_of t, c_of t x ) #\<^sub>\<Gamma> G ; \<Delta>  \<turnstile> s2 \<Leftarrow> t2" using check_let2I * by blast
  qed
next
  case (check_varI u \<Theta> \<Phi> \<B> \<Gamma> \<Delta> \<tau>' v \<tau> s)
  show ?case proof(rule Typing.check_varI)
    have "atom u \<sharp> t2" using u_fresh_t by auto
    thus \<open>atom u \<sharp> (\<Theta>, \<Phi>, \<B>, \<Gamma>, \<Delta>, \<tau>', v, t2)\<close> using check_varI  fresh_prodN by auto
    show \<open>\<Theta> ; \<B> ; \<Gamma>  \<turnstile> v \<Leftarrow> \<tau>'\<close> using check_varI by auto
    show \<open> \<Theta> ; \<Phi> ; \<B> ; \<Gamma> ; (u, \<tau>') #\<^sub>\<Delta> \<Delta>  \<turnstile> s \<Leftarrow> t2\<close> using check_varI by auto
  qed
next
  case (check_assignI \<Delta> u \<tau> P G v z \<tau>')
  then show ?case using Typing.check_assignI by (meson subtype_trans)
next
  case (check_whileI \<Delta> G P s1 z s2 \<tau>')
  then show ?case using Typing.check_whileI by (meson subtype_trans)
next
  case (check_seqI \<Delta> G P s1 z s2 \<tau>)
  then show ?case using Typing.check_seqI by blast
next
  case (check_caseI \<Delta> \<Gamma> \<Theta> tid cs \<tau> v z)
  then show ?case using Typing.check_caseI subtype_trans   by meson

qed


lemma subtype_let:
  fixes s'::s and cs::branch_s and css::branch_list and v::v
  shows "\<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>   \<turnstile> AS_let x e\<^sub>1 s \<Leftarrow> \<tau> \<Longrightarrow> \<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>  \<turnstile> e\<^sub>1 \<Rightarrow> \<tau>\<^sub>1 \<Longrightarrow> 
        \<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>  \<turnstile> e\<^sub>2 \<Rightarrow> \<tau>\<^sub>2 \<Longrightarrow> \<Theta> ; \<B> ; GNil \<turnstile> \<tau>\<^sub>2 \<lesssim> \<tau>\<^sub>1 \<Longrightarrow> \<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>   \<turnstile> AS_let x e\<^sub>2 s \<Leftarrow> \<tau>" and
     "check_branch_s \<Theta> \<Phi>  {||} GNil \<Delta> tid dc const v cs \<tau> \<Longrightarrow> True" and 
    "check_branch_list \<Theta> \<Phi>  {||} \<Gamma> \<Delta> tid dclist v css \<tau> \<Longrightarrow> True"
proof(nominal_induct GNil  \<Delta> "AS_let x e\<^sub>1 s" \<tau> and \<tau> and \<tau> avoiding: e\<^sub>2  \<tau>\<^sub>1 \<tau>\<^sub>2 
         rule: check_s_check_branch_s_check_branch_list.strong_induct)
  case (check_letI x1 \<Theta> \<Phi> \<B>  \<Delta> \<tau>1 z1 s1 b1 c1)
  obtain z2 and b2 and c2 where t2:"\<tau>\<^sub>2 = \<lbrace> z2 : b2 | c2 \<rbrace> \<and> atom z2 \<sharp> (x1, \<Theta>, \<Phi>, \<B>, GNil, \<Delta>, e\<^sub>2, \<tau>1, s1) " 
    using obtain_fresh_z by metis

  obtain z1a and b1a and c1a where t1:"\<tau>\<^sub>1 = \<lbrace> z1a : b1a  | c1a \<rbrace> \<and> atom z1a \<sharp> x1" using infer_e_uniqueness check_letI by  metis
  hence t3: " \<lbrace> z1a : b1a  | c1a \<rbrace>  =  \<lbrace> z1 : b1  | c1 \<rbrace> " using infer_e_uniqueness check_letI by  metis 

  have beq: "b1a = b2 \<and> b2 = b1" using check_letI subtype_eq_base t1 t2 t3 by metis

  have " \<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>   \<turnstile> AS_let x1  e\<^sub>2 s1 \<Leftarrow> \<tau>1"  proof
    show \<open>atom x1 \<sharp> (\<Theta>, \<Phi>, \<B>, GNil, \<Delta>, e\<^sub>2, \<tau>1)\<close> using check_letI t2 fresh_prodN by metis
    show \<open>atom z2 \<sharp> (x1, \<Theta>, \<Phi>, \<B>, GNil, \<Delta>, e\<^sub>2, \<tau>1, s1)\<close> using check_letI t2  using check_letI t2 fresh_prodN by metis
    show \<open>\<Theta> ; \<Phi> ; \<B> ; GNil ; \<Delta>  \<turnstile> e\<^sub>2 \<Rightarrow> \<lbrace> z2 : b2  | c2 \<rbrace>\<close> using check_letI t2 by metis
 
    have \<open> \<Theta> ; \<Phi> ; \<B> ; GNil@(x1, b2, c2[z2::=[ x1 ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> GNil ; \<Delta>  \<turnstile> s1 \<Leftarrow> \<tau>1\<close>
    proof(rule ctx_subtype_s)
      have "c1a[z1a::=[ x1 ]\<^sup>v]\<^sub>c\<^sub>v = c1[z1::=[ x1 ]\<^sup>v]\<^sub>c\<^sub>v" using subst_v_flip_eq_two subst_v_c_def t3 \<tau>.eq_iff by metis
      thus  \<open> \<Theta> ; \<Phi> ; \<B> ; GNil @ (x1, b2, c1a[z1a::=[ x1 ]\<^sup>v]\<^sub>c\<^sub>v) #\<^sub>\<Gamma> GNil ; \<Delta>  \<turnstile> s1 \<Leftarrow> \<tau>1\<close> using check_letI beq append_g.simps subst_defs by metis
      show \<open>\<Theta> ; \<B> ; GNil  \<turnstile> \<lbrace> z2 : b2  | c2 \<rbrace> \<lesssim> \<lbrace> z1a : b2  | c1a \<rbrace>\<close> using check_letI beq  t1 t2 by metis
      have "atom x1 \<sharp> c2" using t2 check_letI \<tau>_fresh_c fresh_prodN  by blast
      moreover have "atom x1 \<sharp> c1a" using t1 check_letI \<tau>_fresh_c fresh_prodN  by blast
      ultimately show \<open>atom x1 \<sharp> (z1a, z2, c1a, c2)\<close> using t1 t2 fresh_prodN fresh_x_neq by metis
    qed

    thus \<open> \<Theta> ; \<Phi> ; \<B> ; (x1, b2, c2[z2::=[ x1 ]\<^sup>v]\<^sub>v) #\<^sub>\<Gamma> GNil ; \<Delta>  \<turnstile> s1 \<Leftarrow> \<tau>1\<close> using append_g.simps subst_defs by metis
  qed

  moreover have "AS_let x1  e\<^sub>2 s1 = AS_let x  e\<^sub>2 s" using check_letI s_branch_s_branch_list.eq_iff  by metis

  ultimately show ?case  by metis

qed(auto+)

end