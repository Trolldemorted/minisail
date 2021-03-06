theory Methods
(* Its seems that it's best to load the Eisbach tools last *)
imports  WellformedLemmas  "HOL-Eisbach.Eisbach_Tools" 
begin

(* See Eisbach/Examples.thy as well as Eisbach User Manual. *)

(* Freshness for various substitution situations. It seems that if undirected and we throw all the 
facts at them to try to solve in one shot, the automatic methods are *sometimes*  unable
to handle the different variants, so some guidance is needed. 
First we split into subgoals using fresh_prodN and intro conjI *)


(* The 'add', for example, will be induction premises that will contain freshness facts or freshness conditions from 
prior obtains *)

(* Use different arguments for different things or just lump into one bucket *)

method fresh_subst_mth_aux uses add = (
       (match conclusion in  "atom z \<sharp> (\<Gamma>::\<Gamma>)[x::=v]\<^sub>\<Gamma>\<^sub>v" for z x v \<Gamma>  \<Rightarrow> \<open>auto simp add: fresh_subst_gv_if[of "atom z" \<Gamma> v x] add\<close>)
     | (match conclusion in  "atom z \<sharp> (v'::v)[x::=v]\<^sub>v\<^sub>v" for z x v v' \<Rightarrow> \<open>auto simp add: v.fresh fresh_subst_v_if pure_fresh subst_v_v_def  add\<close> )
     | (match conclusion in  "atom z \<sharp> (ce::ce)[x::=v]\<^sub>c\<^sub>e\<^sub>v" for z x v ce \<Rightarrow> \<open>auto simp add: fresh_subst_v_if subst_v_ce_def  add\<close> )
(* tbc delta and types *)
     | (auto simp add: add x_fresh_b pure_fresh) (* Cases where there is no subst and so can most likely get what we want from induction premises *)
)

method fresh_mth uses add = (
     (unfold fresh_prodN, intro conjI)?,
     (fresh_subst_mth_aux add: add)+)

(* do base subst *)


(*
method subst_tuple_mth uses add = (
        (unfold fresh_prodN), (simp add: add  )+,
        (rule,metis fresh_z_subst_g add fresh_Pair ),
        (metis fresh_subst_dv add fresh_Pair ) )
*)

notepad
begin
  fix \<Gamma>::\<Gamma> and z::x and x::x and v::v and \<Theta>::\<Theta> and v'::v and w::x and tyid::string and dc::string and b::b and ce::ce and bv::bv

  assume as:"atom z \<sharp> (\<Gamma>,v',\<Theta>, v,w,ce) \<and> atom bv \<sharp>  (\<Gamma>,v',\<Theta>, v,w,ce,b) "

  have "atom z \<sharp> \<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v" 
    by (fresh_mth add: as)

  hence "atom z \<sharp> v'[x::=v]\<^sub>v\<^sub>v" 
    by (fresh_mth add: as)

  hence "atom z \<sharp> \<Gamma>" 
   by (fresh_mth add: as)

  hence "atom z \<sharp> \<Theta>" 
    by (fresh_mth add: as)

  hence "atom z \<sharp>  (CE_val v == ce)[x::=v]\<^sub>c\<^sub>v"
    using as by auto

  hence "atom bv \<sharp>  (CE_val v == ce)[x::=v]\<^sub>c\<^sub>v"
     using as by auto

  have "atom z \<sharp> (\<Theta>,\<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v,v'[x::=v]\<^sub>v\<^sub>v,w, V_pair v v, V_consp tyid dc b v, (CE_val v == ce)[x::=v]\<^sub>c\<^sub>v) " 
    by (fresh_mth add: as)

  have "atom bv \<sharp> (\<Theta>,\<Gamma>[x::=v]\<^sub>\<Gamma>\<^sub>v,v'[x::=v]\<^sub>v\<^sub>v,w, V_pair v v, V_consp tyid dc b v) " 
    by (fresh_mth add: as)

end



method supp_calc = (metis (mono_tags, hide_lams) pure_supp  c.supp e.supp v.supp supp_l_empty opp.supp sup_bot.right_neutral supp_at_base)

(*
method subst_mth = (metis  subst_g_inside  infer_e_wb infer_v_wb infer_v_wb)

method subst_tuple_mth uses add = (
        (unfold fresh_prodN), (simp add: add  )+,
        (rule,metis fresh_z_subst_g add fresh_Pair ),
        (metis fresh_subst_dv add fresh_Pair ) )

method many_rules uses add = ( (rule+),((simp add: add)+)?)
*)

end