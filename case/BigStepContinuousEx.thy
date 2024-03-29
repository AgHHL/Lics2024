theory BigStepContinuousEx
  imports BigStepContParallel
begin

definition A :: pname where "A = ''a''"
definition B :: pname where "B = ''b''"
definition C :: pname where "C = ''c''"
definition X :: char where "X = CHR ''x''"
definition Y :: char where "Y = CHR ''y''"
definition Z :: char where "Z = CHR ''z''"
definition ch1 :: cname where "ch1 = ''ch1''"
definition ch2 :: cname where "ch2 = ''ch2''"

lemma pname_neq [simp]: "A \<noteq> B" by (auto simp add: A_def B_def)

subsection \<open>Basic tests\<close>

lemma test_ode_unique:
  assumes "spec_of c Q"
  shows
  "spec_of (Cont (ODE ((\<lambda>_ _. 0)(X := (\<lambda>_. 1)))) (\<lambda>s. val s X < 1); c)
           (wait_c (\<lambda>s0 t s. s = upd s0 X (val s0 X + t)) (\<lambda>s. 1 - val s X)
                       (\<lambda>d s. Q (upd s X (val s X + d))))"
proof -
  have 1: "paramODEsol (ODE ((\<lambda>_ _. 0)(X := \<lambda>_. 1))) (\<lambda>s. val s X < 1)
                       (\<lambda>s t. (rpart s)(X := val s X + t)) (\<lambda>s. 1 - val s X)"
    unfolding paramODEsol_def apply clarify
    subgoal for s
      apply (rule conjI)
      subgoal apply (cases s)
        by (auto simp add: rpart.simps val.simps)
      apply (cases "val s X < 1")
      subgoal apply auto
        subgoal
          unfolding ODEsol_def solves_ode_def has_vderiv_on_def
          apply auto
          apply (rule exI[where x="1"])
          apply auto
          apply (rule has_vector_derivative_projI)
          apply (auto simp add: state2vec_def)
          apply (rule has_vector_derivative_eq_rhs)
           apply (auto intro!: derivative_intros)[1]
          by simp
        subgoal for t
          apply (cases s) by (auto simp add: updr.simps val.simps)
        subgoal 
          apply (cases s) by (auto simp add: updr.simps val.simps)
        done
      subgoal by auto
      done
    done
  have 2: "local_lipschitz {- 1<..} UNIV (\<lambda>t v. ODE2Vec (ODE ((\<lambda>_ _. 0)(X := \<lambda>_. 1))) (vec2state v))"
  proof -
    have eq: "(\<chi> a. (if a = X then \<lambda>_. 1 else (\<lambda>_. 0)) (($) v)) = (\<chi> a. if a = X then 1 else 0)" for v::vec
      by auto
    show ?thesis
      unfolding fun_upd_def vec2state_def
      apply (auto simp add: state2vec_def eq)
      by (rule local_lipschitz_constI)
  qed
  show ?thesis
    apply (rule spec_of_post)
     apply (rule Valid_cont_unique_sp)
       apply (rule assms)
      apply (rule 1) apply (rule 2)
    apply clarify apply (simp only: updr_rpart_simp1)
    apply (rule wait_c_mono)
    by (rule entails_triv)
qed

lemma test_interrupt_unique:
  "spec_of (Interrupt (ODE ((\<lambda>_ _. 0)(X := (\<lambda>_. 1)))) (\<lambda>s. val s X < 1)
                      [(dh[?]Y, Skip)] Skip)
           (interrupt_sol_c (\<lambda>s0 t s. s = upd s0 X (val s0 X + t)) (\<lambda>s. 1 - val s X)
                            (\<lambda>d s. init (upd s X (val s X + d)))
                            [InSpec2 dh (\<lambda>d v s. init (upd (upd s X (val s X + d)) Y v))])"
proof -
  have 1: "paramODEsol (ODE ((\<lambda>_ _. 0)(X := \<lambda>_. 1))) (\<lambda>s. val s X < 1)
                       (\<lambda>s0 t. (rpart s0)(X := val s0 X + t)) (\<lambda>s0. 1 - val s0 X)"
    unfolding paramODEsol_def apply clarify
    subgoal for s
      apply (rule conjI)
      subgoal apply (cases s)
        by (auto simp add: rpart.simps val.simps)
      apply (cases "val s X < 1")
      subgoal apply auto
        subgoal
          unfolding ODEsol_def solves_ode_def has_vderiv_on_def
          apply auto
          apply (rule exI[where x="1"])
          apply auto
          apply (rule has_vector_derivative_projI)
          apply (auto simp add: state2vec_def)
          apply (rule has_vector_derivative_eq_rhs)
           apply (auto intro!: derivative_intros)[1]
          by simp
        subgoal for t
          apply (cases s) by (auto simp add: updr.simps val.simps)
        subgoal 
          apply (cases s) by (auto simp add: updr.simps val.simps)
        done
      subgoal by auto
      done
    done
  have 2: "local_lipschitz {- 1<..} UNIV (\<lambda>t v. ODE2Vec (ODE ((\<lambda>_ _. 0)(X := \<lambda>_. 1))) (vec2state v))"
  proof -
    have eq: "(\<chi> a. (if a = X then \<lambda>_. 1 else (\<lambda>_. 0)) (($) v)) = (\<chi> a. if a = X then 1 else 0)" for v::vec
      by auto
    show ?thesis
      unfolding fun_upd_def vec2state_def
      apply (auto simp add: state2vec_def eq)
      by (rule local_lipschitz_constI)
  qed
  let ?specs = "[InSpec dh Y init]"
  show ?thesis
    apply (rule spec_of_post)
     apply (rule spec_of_interrupt_unique[where specs="?specs"])
        apply (rule 1) apply (rule 2)
      apply (auto intro!: rel_list.intros) apply (rule spec_of_es.intros)
      apply (rule spec_of_skip)
     apply (rule spec_of_skip)
    subgoal for s0
      apply (simp only: updr_rpart_simp1)
      apply (rule interrupt_sol_mono)
      subgoal by (rule entails_triv)
      subgoal apply (auto intro!: rel_list.intros spec2_entails.intros)
        subgoal for d v s0 apply (simp only: substr_assn2_def updr_rpart_simp2)
          by (rule entails_triv)
        done
      done
    done
qed

subsection \<open>Examples\<close>

subsubsection \<open>Example 1\<close>

text \<open>
  The program to be analyzed is:
   x := 0; (ch!1; <x_dot = 2> |> dh?Y) \<squnion> (ch!2; <x_dot = 1> |> dh?Y)
|| ch?Y; wait(Y); dh!0
\<close>

definition ex1a :: "'a proc" where
  "ex1a = (X ::= (\<lambda>_. 0); IChoice
      (Cm (ch1[!](\<lambda>_. 1)); Interrupt (ODE ((\<lambda>_ _. 0)(X := (\<lambda>_. 2)))) (\<lambda>_. True)
                                     [(ch2[?]Y, Skip)] Skip)
      (Cm (ch1[!](\<lambda>_. 2)); Interrupt (ODE ((\<lambda>_ _. 0)(X := (\<lambda>_. 1)))) (\<lambda>_. True)
                                     [(ch2[?]Y, Skip)] Skip))"

lemma ex1a_ode:
  assumes "spec_of c1 Q1" "spec_of c2 Q2"
  shows
  "spec_of (Interrupt (ODE ((\<lambda>_ _. 0)(X := \<lambda>_. 2))) (\<lambda>_. True) [(ch2[?]Y, c2)] c1)
           (wait_in_c (\<lambda>s0 t s. s = upd s0 X (val s0 X + 2 * t))
               ch2 (\<lambda>d v. Q2 {{Y := (\<lambda>_. v)}} {{X := (\<lambda>s. val s X + 2 * d)}}))"
proof -
  have 1: "paramODEsolInf (ODE ((\<lambda>_ _. 0)(X := \<lambda>_. 2)))
                          (\<lambda>s0 t. (rpart s0)(X := val s0 X + 2 * t))"
    unfolding paramODEsolInf_def apply clarify
    subgoal for s
      apply (rule conjI)
      subgoal apply (cases s)
        by (auto simp add: rpart.simps val.simps)
      unfolding ODEsolInf_def solves_ode_def has_vderiv_on_def
      apply auto
      apply (rule exI[where x="1"])
      apply auto
      apply (rule has_vector_derivative_projI)
      apply (auto simp add: state2vec_def)
      apply (rule has_vector_derivative_eq_rhs)
       apply (auto intro!: derivative_intros)[1]
      by simp
    done
  have 2: "local_lipschitz {- 1<..} UNIV (\<lambda>t v. ODE2Vec (ODE ((\<lambda>_ _. 0)(X := \<lambda>_. 2))) (vec2state v))"
  proof -
    have eq: "(\<chi> a. (if a = X then \<lambda>_. 2 else (\<lambda>_. 0)) (($) v)) = (\<chi> a. if a = X then 2 else 0)" for v::vec
      by auto
    show ?thesis
      unfolding fun_upd_def vec2state_def
      apply (auto simp add: state2vec_def eq)
      by (rule local_lipschitz_constI)
  qed
  let ?specs = "[InSpec ch2 Y Q2]"
  show ?thesis
    apply (rule spec_of_post)
     apply (rule spec_of_interrupt_inf_unique[where specs="?specs"])
        apply (rule 1) apply (rule 2)
      apply (auto intro!: rel_list.intros) apply (rule spec_of_es.intros)
      apply (rule assms) apply (rule assms)
    apply (subst interrupt_solInf_c_in)
    subgoal for s0
      apply (simp only: updr_rpart_simp1)
      apply (rule wait_in_c_mono)
      apply (cases s0)
      apply (auto simp add: substr_assn2_def subst_assn2_def updr.simps rpart.simps val.simps upd.simps)
      by (rule entails_triv)
    done
qed

lemma ex1a_ode2:
  assumes "spec_of c1 Q1" "spec_of c2 Q2"
  shows
  "spec_of (Interrupt (ODE ((\<lambda>_ _. 0)(X := (\<lambda>_. 1)))) (\<lambda>_. True)
                      [(dh[?]Y, c2)] c1)
           (wait_in_c (\<lambda>s0 t s. s = upd s0 X (val s0 X + t))
              dh (\<lambda>d v. Q2 {{Y := (\<lambda>_. v)}} {{X := (\<lambda>s. val s X + d)}}))"
proof -
  have 1: "paramODEsolInf (ODE ((\<lambda>_ _. 0)(X := \<lambda>_. 1)))
                       (\<lambda>s0 t. (rpart s0)(X := val s0 X + t))"
    unfolding paramODEsolInf_def apply clarify
    subgoal for s
      apply (rule conjI)
      subgoal apply (cases s)
        by (auto simp add: rpart.simps val.simps)
      unfolding ODEsolInf_def solves_ode_def has_vderiv_on_def
      apply auto
      apply (rule exI[where x="1"])
      apply auto
      apply (rule has_vector_derivative_projI)
      apply (auto simp add: state2vec_def)
      apply (rule has_vector_derivative_eq_rhs)
       apply (auto intro!: derivative_intros)[1]
      by simp
    done
  have 2: "local_lipschitz {- 1<..} UNIV (\<lambda>t v. ODE2Vec (ODE ((\<lambda>_ _. 0)(X := \<lambda>_. 1))) (vec2state v))"
  proof -
    have eq: "(\<chi> a. (if a = X then \<lambda>_. 1 else (\<lambda>_. 0)) (($) v)) = (\<chi> a. if a = X then 1 else 0)" for v::vec
      by auto
    show ?thesis
      unfolding fun_upd_def vec2state_def
      apply (auto simp add: state2vec_def eq)
      by (rule local_lipschitz_constI)
  qed
  let ?specs = "[InSpec dh Y Q2]"
  show ?thesis
    apply (rule spec_of_post)
     apply (rule spec_of_interrupt_inf_unique[where specs="?specs"])
        apply (rule 1) apply (rule 2)
      apply (auto intro!: rel_list.intros) apply (rule spec_of_es.intros)
      apply (rule assms) apply (rule assms)
    apply (subst interrupt_solInf_c_in)
    subgoal for s0
      apply (simp only: updr_rpart_simp1)
      apply (rule wait_in_c_mono)
      apply (cases s0)
      apply (auto simp add: substr_assn2_def subst_assn2_def updr.simps rpart.simps val.simps upd.simps)
      by (rule entails_triv)
    done
qed

lemma ex1a_sp':
  "spec_of ex1a
     ((wait_out_cv single_id_inv ch1 (\<lambda>_. 1)
        (\<lambda>d. wait_in_c (\<lambda>s0 t s. s = upd s0 X (val s0 X + 2 * t))
               ch2 (\<lambda>d v. init {{Y := (\<lambda>_. v)}} {{X := (\<lambda>s. val s X + 2 * d)}})) \<or>\<^sub>a
       wait_out_cv single_id_inv ch1 (\<lambda>_. 2)
        (\<lambda>d. wait_in_c (\<lambda>s0 t s. s = upd s0 X (val s0 X + t))
               ch2 (\<lambda>d v. init {{Y := (\<lambda>_. v)}} {{X := (\<lambda>s. val s X + d)}})))
      {{X := (\<lambda>_. 0)}})"
  unfolding ex1a_def
  apply (rule spec_of_post)
   apply (rule Valid_assign_sp)
   apply (rule spec_of_ichoice)
    apply (rule Valid_send_sp)
    apply (rule ex1a_ode)
     apply (rule spec_of_skip) apply (rule spec_of_skip)
   apply (rule Valid_send_sp)
   apply (rule ex1a_ode2)
    apply (rule spec_of_skip) apply (rule spec_of_skip)
  apply auto by (rule entails_triv)

lemma ex1a_sp:
  "spec_of ex1a
     ((wait_out_cv (\<lambda>s0 t s. s = upd s0 X 0) ch1 (\<lambda>_. 1)
        (\<lambda>d. wait_in_c (\<lambda>s0 t s. s = upd s0 X (2 * t))
               ch2 (\<lambda>d v. init {{Y := (\<lambda>_. v)}} {{X := (\<lambda>s. val s X + 2 * d)}} {{ X := (\<lambda>_. 0) }})) \<or>\<^sub>a
       wait_out_cv (\<lambda>s0 t s. s = upd s0 X 0) ch1 (\<lambda>_. 2)
        (\<lambda>d. wait_in_c (\<lambda>s0 t s. s = upd s0 X t)
               ch2 (\<lambda>d v. init {{Y := (\<lambda>_. v)}} {{X := (\<lambda>s. val s X + d)}} {{ X := (\<lambda>_. 0) }}))))"
  apply (rule spec_of_post)
   apply (rule ex1a_sp') apply clarify
  apply (rule entails_trans)
   apply (rule disj_assn_upd)
  apply (rule disj_assn_mono)
  subgoal for s0
    apply (rule entails_trans)
     apply (rule wait_out_cv_upd)
    apply simp apply (rule wait_out_cv_mono)
    apply (rule entails_trans)
     apply (rule wait_in_c_upd)
    apply simp apply (rule wait_in_c_mono)
    by (rule entails_triv)
  subgoal for s0
    apply (rule entails_trans)
     apply (rule wait_out_cv_upd)
    apply simp apply (rule wait_out_cv_mono)
    apply (rule entails_trans)
     apply (rule wait_in_c_upd)
    apply simp apply (rule wait_in_c_mono)
    by (rule entails_triv)
  done    

definition ex1b :: "'a proc" where
  "ex1b = (Cm (ch1[?]Y); Wait (\<lambda>s. val s Y); Cm (ch2[!](\<lambda>_. 0)))"

lemma ex1b_sp:
  "spec_of ex1b
      (wait_in_c single_id_inv ch1
        (\<lambda>d v. wait_c (\<lambda>s0 t s. s = upd s0 Y v) (\<lambda>_. v)
          (\<lambda>d. wait_out_cv (\<lambda>s0 t s. s = upd s0 Y v) ch2 (\<lambda>_. 0)
            (\<lambda>d. init {{Y := (\<lambda>_. v)}}))))"
  unfolding ex1b_def
  apply (rule spec_of_post)
  apply (rule Valid_receive_sp)
   apply (rule Valid_wait_sp)
   apply (rule spec_of_send) apply clarify
  apply (rule wait_in_c_mono)
  apply (rule entails_trans)
   apply (rule wait_c_upd)
  apply simp apply (rule wait_c_mono)
  apply (rule entails_trans)
   apply (rule wait_out_cv_upd)
  apply simp by (rule entails_triv)

lemma ex1':
  "spec_of_global
    (Parallel (Single A ex1a)
              {ch1, ch2}
              (Single B ex1b))
   ((wait_cg
      (merge_inv (single_inv A (\<lambda>s0 t s. s = upd s0 X (2 * t)))
                 (single_inv B (\<lambda>s0 t s. s = upd s0 Y 1)))
      B (\<lambda>_. 1) (\<lambda>d. ((init_single {B, A} {{Y := (\<lambda>_. 1)}}\<^sub>g at B)
                                          {{Y := (\<lambda>_. 0)}}\<^sub>g at A)
                                          {{X := (\<lambda>s. val s X + 2 * d)}}\<^sub>g at A
                                          {{X := (\<lambda>_. 0)}}\<^sub>g at A) \<or>\<^sub>g
     wait_cg
      (merge_inv (single_inv A (\<lambda>s0 t s. s = upd s0 X t))
                 (single_inv B (\<lambda>s0 t s. s = upd s0 Y 2)))
      B (\<lambda>_. 2) (\<lambda>d. ((init_single {B, A} {{Y := (\<lambda>_. 2)}}\<^sub>g at B)
                                          {{Y := (\<lambda>_. 0)}}\<^sub>g at A)
                                          {{X := (\<lambda>s. val s X + d)}}\<^sub>g at A
                                          {{X := (\<lambda>_. 0)}}\<^sub>g at A)))"
  (* Stage 1: merge ex1a_sp and ex1b_sp *)
  apply (rule spec_of_global_post)
   apply (rule spec_of_parallel)
      apply (rule spec_of_single) apply (rule ex1a_sp)
     apply (rule spec_of_single) apply (rule ex1b_sp)
  (* Stage 2: rewrite the assertions *)
    apply auto subgoal for s0
    apply (auto simp: single_assn_simps)
  (* Stage 3: merge the assertions *)
    apply (rule sync_gassn_disj2)
    (* Left branch *)
    subgoal
      apply (rule entails_g_trans)
       apply (rule sync_gassn_outv_in) apply auto
      apply (rule entails_g_trans)
       apply (rule sync_gassn_in_wait_pair) apply auto
      apply (rule wait_cg_mono)
      apply (rule entails_g_trans)
       apply (rule sync_gassn_in_outv') apply auto
      apply (rule entails_g_trans)
       apply (rule sync_gassn_subst_left) apply auto
      apply (rule updg_mono)
      apply (rule entails_g_trans)
       apply (rule sync_gassn_subst_left) apply auto
      apply (rule updg_mono)
      apply (rule entails_g_trans)
       apply (rule sync_gassn_subst_left) apply auto
      apply (rule updg_mono)
      apply (rule entails_g_trans)
       apply (rule sync_gassn_subst_right) apply auto
      apply (rule updg_mono)
      apply (rule entails_g_trans)
      apply (rule sync_gassn_emp) apply auto
      by (rule entails_g_triv)
    (* Right branch *)
    subgoal
      apply (rule entails_g_trans)
       apply (rule sync_gassn_outv_in) apply auto
      apply (rule entails_g_trans)
       apply (rule sync_gassn_in_wait_pair) apply auto
      apply (rule wait_cg_mono)
      apply (rule entails_g_trans)
       apply (rule sync_gassn_in_outv') apply auto
      apply (rule entails_g_trans)
       apply (rule sync_gassn_subst_left) apply auto
      apply (rule updg_mono)
      apply (rule entails_g_trans)
       apply (rule sync_gassn_subst_left) apply auto
      apply (rule updg_mono)
      apply (rule entails_g_trans)
       apply (rule sync_gassn_subst_left) apply auto
      apply (rule updg_mono)
      apply (rule entails_g_trans)
       apply (rule sync_gassn_subst_right) apply auto
      apply (rule updg_mono)
      apply (rule entails_g_trans)
      apply (rule sync_gassn_emp) apply auto
      by (rule entails_g_triv)
    done
  done

lemma ex_inv1:
  assumes "proc_set s0 = {A, B}"
    "t \<in> {0..1}"
    "merge_inv (single_inv A (\<lambda>s0 t s. s = upd s0 X (2 * t)))
        (single_inv B (\<lambda>s0 t s. s = upd s0 Y 1)) s0 t gs"
  shows "valg gs A X \<in> {0..2}"
  apply (rule merge_state_elim[of s0 "{A}" "{B}"])
  subgoal using assms by auto
  subgoal by auto
  subgoal for s1 s2
    using assms(3) apply (elim merge_inv_elim)
    subgoal for s01 s02 s1' s2' apply simp
      apply (elim single_inv_State)
      apply (simp add: valg_merge_state_left valg_merge_state_right single_subst_merge_state1)
      using assms by auto
    done
  done

lemma ex_inv2:
  assumes "proc_set s0 = {A, B}"
    "t \<in> {0..2}"
    "merge_inv (single_inv A (\<lambda>s0 t s. s = upd s0 X t))
        (single_inv B (\<lambda>s0 t s. s = upd s0 Y 2)) s0 t gs"
  shows "valg gs A X \<in> {0..2}"
  apply (rule merge_state_elim[of s0 "{A}" "{B}"])
  subgoal using assms by auto
  subgoal by auto
  subgoal for s1 s2
    using assms(3) apply (elim merge_inv_elim)
    subgoal for s01 s02 s1' s2' apply simp
      apply (elim single_inv_State)
      apply (simp add: valg_merge_state_left valg_merge_state_right single_subst_merge_state1)
      using assms by auto
    done
  done

lemma ex1'':
  assumes "proc_set s0 = {A, B}"
  shows
  "((wait_cg
      (merge_inv (single_inv A (\<lambda>s0 t s. s = upd s0 X (2 * t)))
                 (single_inv B (\<lambda>s0 t s. s = upd s0 Y 1)))
      B (\<lambda>_. 1) (\<lambda>d. (((init_single {B, A} {{Y := (\<lambda>_. 1)}}\<^sub>g at B)
                                           {{Y := (\<lambda>_. 0)}}\<^sub>g at A)
                                           {{X := (\<lambda>s. val s X + 2 * d)}}\<^sub>g at A)
                                           {{X := (\<lambda>_. 0)}}\<^sub>g at A) \<or>\<^sub>g
     wait_cg
      (merge_inv (single_inv A (\<lambda>s0 t s. s = upd s0 X t))
                 (single_inv B (\<lambda>s0 t s. s = upd s0 Y 2)))
      B (\<lambda>_. 2) (\<lambda>d. (((init_single {B, A} {{Y := (\<lambda>_. 2)}}\<^sub>g at B)
                                           {{Y := (\<lambda>_. 0)}}\<^sub>g at A)
                                           {{X := (\<lambda>s. val s X + d)}}\<^sub>g at A)
                                           {{X := (\<lambda>_. 0)}}\<^sub>g at A))) s0 \<Longrightarrow>\<^sub>G
    (wait_inv_cg (\<lambda>gs. valg gs A X \<in> {0..2})
        (\<lambda>s0 s tr. valg s A X = 2 \<and> init_single {B, A} s s tr)) s0"
  apply (rule entails_g_disj)
  subgoal
    (* Left branch *)
    apply (rule entails_g_trans)
     apply (rule wait_inv_cgI[where d=1 and J="\<lambda>gs. valg gs A X \<in> {0..2}"])
       apply (simp only: valg_def[symmetric]) apply auto[1]
    subgoal using assms ex_inv1[of s0] by blast
    apply (rule wait_inv_cg_mono)
    apply (rule entails_g_trans)
    apply (rule gassn_subst)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (simp only: valg_def[symmetric]) apply auto
    unfolding entails_g_def apply auto
    subgoal for s tr apply (elim init_single.cases)
      by (auto simp add: entails_g_def X_def Y_def A_def B_def)
    subgoal for s tr apply (elim init_single.cases)
      by (auto intro: init_single.intros)
done
  subgoal
    (* Right branch *)
    apply (rule entails_g_trans)
     apply (rule wait_inv_cgI[where d=2 and J="\<lambda>gs. valg gs A X \<in> {0..2}"])
       apply (simp only: valg_def[symmetric]) apply auto[1]
    subgoal using assms ex_inv2[of s0] by blast
    apply (rule wait_inv_cg_mono)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (simp only: valg_def[symmetric])
    unfolding entails_g_def apply auto
    subgoal for s tr apply (elim init_single.cases)
      by (auto simp add: entails_g_def X_def Y_def A_def B_def)
    subgoal for s tr apply (elim init_single.cases)
      by (auto intro: init_single.intros)
    done
  done

lemma ex1:
  "spec_of_global
    (Parallel (Single A ex1a)
              {ch1, ch2}
              (Single B ex1b))
    (wait_inv_cg (\<lambda>gs. valg gs A X \<in> {0..2})
      (\<lambda>s0 s tr. valg s A X = 2 \<and> init_single {B, A} s s tr))"
  apply (rule spec_of_global_post)
   apply (rule ex1') apply clarify
  apply (rule ex1'') by auto

subsubsection \<open>Example 2\<close>

text \<open>
  For the second example, we redo the previous example but with loops.

  The program to be analyzed is:
   (x := 0; (ch!1; <x_dot = 2> |> dh?Y) \<squnion> (ch!2; <x_dot = 1> |> dh?Y))*
|| (ch?Y; wait(Y); dh!0)*
\<close>

definition ex2a :: "'a proc" where
  "ex2a = Rep (X ::= (\<lambda>_. 0); IChoice
      (Cm (ch1[!](\<lambda>_. 1)); Interrupt (ODE ((\<lambda>_ _. 0)(X := (\<lambda>_. 2)))) (\<lambda>_. True)
                                     [(ch2[?]Y, Skip)] Skip)
      (Cm (ch1[!](\<lambda>_. 2)); Interrupt (ODE ((\<lambda>_ _. 0)(X := (\<lambda>_. 1)))) (\<lambda>_. True)
                                     [(ch2[?]Y, Skip)] Skip))"

definition ex2b :: "'a proc" where
  "ex2b = Rep (Cm (ch1[?]Y); Wait (\<lambda>s. val s Y); Cm (ch2[!](\<lambda>_. 0)))"

fun ex2a_c' :: "nat \<Rightarrow> 'a assn2" where
  "ex2a_c' 0 = init"
| "ex2a_c' (Suc n) =
   ((wait_out_cv single_id_inv ch1 (\<lambda>_. 1)
      (\<lambda>d. wait_in_c (\<lambda>s0 t s. s = upd s0 X (val s0 X + 2 * t))
             ch2 (\<lambda>d v. (ex2a_c' n) {{Y := (\<lambda>_. v)}} {{X := (\<lambda>s. val s X + 2 * d)}})) \<or>\<^sub>a
     wait_out_cv single_id_inv ch1 (\<lambda>_. 2)
      (\<lambda>d. wait_in_c (\<lambda>s0 t s. s = upd s0 X (val s0 X + t))
             ch2 (\<lambda>d v. (ex2a_c' n) {{Y := (\<lambda>_. v)}} {{X := (\<lambda>s. val s X + d)}})))
    {{X := (\<lambda>_. 0)}})"

fun ex2a_c :: "nat \<Rightarrow> 'a assn2" where
  "ex2a_c 0 = init"
| "ex2a_c (Suc n) =
   ((wait_out_cv (\<lambda>s0 t s. s = upd s0 X 0) ch1 (\<lambda>_. 1)
      (\<lambda>d. wait_in_c (\<lambda>s0 t s. s = upd s0 X (2 * t))
             ch2 (\<lambda>d v. (ex2a_c n) {{Y := (\<lambda>_. v)}} {{X := (\<lambda>s. val s X + 2 * d)}} {{ X := (\<lambda>_. 0) }})) \<or>\<^sub>a
     wait_out_cv (\<lambda>s0 t s. s = upd s0 X 0) ch1 (\<lambda>_. 2)
      (\<lambda>d. wait_in_c (\<lambda>s0 t s. s = upd s0 X t)
             ch2 (\<lambda>d v. (ex2a_c n) {{Y := (\<lambda>_. v)}} {{X := (\<lambda>s. val s X + d)}} {{ X := (\<lambda>_. 0) }}))))"

lemma ex2a_sp':
  "spec_of ex2a
           (\<exists>\<^sub>an. ex2a_c' n)"
  unfolding ex2a_def
  apply (rule spec_of_rep)
  subgoal for n
    apply (induction n)
     apply simp apply (rule spec_of_skip)
    subgoal premises pre for n
      apply (simp only: RepN.simps ex2a_c'.simps)
      apply (subst spec_of_seq_assoc)
      apply (rule Valid_assign_sp)
      unfolding spec_of_ichoice_distrib
      apply (rule spec_of_ichoice)
      subgoal
        (* Left part *)
        apply (subst spec_of_seq_assoc)
        apply (rule Valid_send_sp)
        apply (subst spec_of_interrupt_distrib) apply auto
        apply (rule ex1a_ode)
        apply (subst spec_of_skip_left) apply (rule pre)
        apply (subst spec_of_skip_left) by (rule pre)
      subgoal
        (* Right part *)
        apply (subst spec_of_seq_assoc)
        apply (rule Valid_send_sp)
        apply (subst spec_of_interrupt_distrib) apply auto
        apply (rule ex1a_ode2)
        apply (subst spec_of_skip_left) apply (rule pre)
        apply (subst spec_of_skip_left) by (rule pre)
      done
    done
  done

lemma ex2a_c_entails:
  "ex2a_c' n s0 \<Longrightarrow>\<^sub>A ex2a_c n s0"
proof (induction n arbitrary: s0)
  case 0
  then show ?case
    by (auto intro: entails_triv)
next
  case (Suc n)
  show ?case
    apply simp
    apply (rule entails_trans)
     apply (rule disj_assn_upd)
    apply (rule disj_assn_mono)
    subgoal
      apply (rule entails_trans)
       apply (rule wait_out_cv_upd)
      apply simp apply (rule wait_out_cv_mono)
      apply (rule entails_trans)
       apply (rule wait_in_c_upd)
      apply simp apply (rule wait_in_c_mono)
      apply (rule upd_mono) apply (rule upd_mono) apply (rule upd_mono)
      by (rule Suc)
    subgoal
      apply (rule entails_trans)
       apply (rule wait_out_cv_upd)
      apply simp apply (rule wait_out_cv_mono)
      apply (rule entails_trans)
       apply (rule wait_in_c_upd)
      apply simp apply (rule wait_in_c_mono)
      apply (rule upd_mono) apply (rule upd_mono) apply (rule upd_mono)
      by (rule Suc)
    done
qed

lemma ex2a_sp:
  "spec_of ex2a
           (\<exists>\<^sub>an. ex2a_c n)"
  apply (rule spec_of_post)
   apply (rule ex2a_sp') apply clarify
  apply (rule exists_assn_mono)
  by (rule ex2a_c_entails)

fun ex2b_c :: "nat \<Rightarrow> 'a assn2" where
  "ex2b_c 0 = init"
| "ex2b_c (Suc n) =
    (wait_in_c single_id_inv ch1
      (\<lambda>d v. wait_c (\<lambda>s0 t s. s = upd s0 Y v) (\<lambda>_. v)
        (\<lambda>d. wait_out_cv (\<lambda>s0 t s. s = upd s0 Y v) ch2 (\<lambda>_. 0) (\<lambda>d. ex2b_c n {{Y := (\<lambda>_. v)}}))))"

lemma ex2b_sp:
  "spec_of ex2b
           (\<exists>\<^sub>an. ex2b_c n)"
  unfolding ex2b_def
  apply (rule spec_of_rep)
  subgoal for n
    apply (induction n)
     apply simp apply (rule spec_of_skip)
    subgoal premises pre for n
      apply simp
      apply (subst spec_of_seq_assoc)
      apply (rule spec_of_post)
      apply (rule Valid_receive_sp)
      apply (subst spec_of_seq_assoc)
      apply (rule Valid_wait_sp)
      apply (rule Valid_send_sp)
       apply (rule pre) apply clarify
      apply (rule wait_in_c_mono)
      apply (rule entails_trans)
       apply (rule wait_c_upd)
      apply simp apply (rule wait_c_mono)
      apply (rule entails_trans)
       apply (rule wait_out_cv_upd)
      apply simp apply (rule wait_out_cv_mono)
      by (rule entails_triv)
    done
  done

lemma ex2':
  "sync_gassn {ch1, ch2} {A} {B}
    (single_assn A (ex2a_c (Suc n1)))
    (single_assn B (ex2b_c (Suc n2))) s0 \<Longrightarrow>\<^sub>G
   ((wait_cg
      (merge_inv (single_inv A (\<lambda>s0 t s. s = upd s0 X (2 * t)))
                 (single_inv B (\<lambda>s0 t s. s = upd s0 Y 1)))
      B (\<lambda>_. 1) (\<lambda>d. (((sync_gassn {ch1, ch2} {A} {B}
             (single_assn A (ex2a_c n1))
             (single_assn B (ex2b_c n2))
             {{Y := (\<lambda>_. 1)}}\<^sub>g at B)
             {{Y := (\<lambda>_. 0)}}\<^sub>g at A)
             {{X := (\<lambda>s. val s X + 2 * d)}}\<^sub>g at A)
             {{X := (\<lambda>_. 0)}}\<^sub>g at A) \<or>\<^sub>g
     wait_cg
      (merge_inv (single_inv A (\<lambda>s0 t s. s = upd s0 X t))
                 (single_inv B (\<lambda>s0 t s. s = upd s0 Y 2)))
      B (\<lambda>_. 2) (\<lambda>d. (((sync_gassn {ch1, ch2} {A} {B}
             (single_assn A (ex2a_c n1))
             (single_assn B (ex2b_c n2))
             {{Y := (\<lambda>_. 2)}}\<^sub>g at B)
             {{Y := (\<lambda>_. 0)}}\<^sub>g at A)
             {{X := (\<lambda>s. val s X + d)}}\<^sub>g at A)
             {{X := (\<lambda>_. 0)}}\<^sub>g at A))) s0"
  apply (auto simp add: single_assn_simps)
  apply (rule sync_gassn_disj2)
  (* Left branch *)
  subgoal
    apply (rule entails_g_trans)
     apply (rule sync_gassn_outv_in) apply auto
    apply (rule entails_g_trans)
     apply (rule sync_gassn_in_wait_pair) apply auto
    apply (rule wait_cg_mono)
    apply (rule entails_g_trans)
     apply (rule sync_gassn_in_outv') apply auto
    apply (rule entails_g_trans)
     apply (rule sync_gassn_subst_left) apply auto
    apply (rule updg_mono)
    apply (rule entails_g_trans)
     apply (rule sync_gassn_subst_left) apply auto
    apply (rule updg_mono)
    apply (rule entails_g_trans)
     apply (rule sync_gassn_subst_left) apply auto
    apply (rule updg_mono)
    apply (rule entails_g_trans)
     apply (rule sync_gassn_subst_right) apply auto
    by (rule entails_g_triv)
  subgoal
    apply (rule entails_g_trans)
     apply (rule sync_gassn_outv_in) apply auto
    apply (rule entails_g_trans)
     apply (rule sync_gassn_in_wait_pair) apply auto
    apply (rule wait_cg_mono)
    apply (rule entails_g_trans)
     apply (rule sync_gassn_in_outv') apply auto
    apply (rule entails_g_trans)
     apply (rule sync_gassn_subst_left) apply auto
    apply (rule updg_mono)
    apply (rule entails_g_trans)
     apply (rule sync_gassn_subst_left) apply auto
    apply (rule updg_mono)
    apply (rule entails_g_trans)
     apply (rule sync_gassn_subst_left) apply auto
    apply (rule updg_mono)
    apply (rule entails_g_trans)
     apply (rule sync_gassn_subst_right) apply auto
    apply (rule updg_mono)
    by (rule entails_g_triv)
  done

lemma ex2'':
  assumes "proc_set s0 = {A, B}"
  shows
   "((wait_cg
      (merge_inv (single_inv A (\<lambda>s0 t s. s = upd s0 X (2 * t)))
                 (single_inv B (\<lambda>s0 t s. s = upd s0 Y 1)))
      B (\<lambda>_. 1) (\<lambda>d. (((sync_gassn {ch1, ch2} {A} {B}
             (single_assn A (ex2a_c n1))
             (single_assn B (ex2b_c n2))
             {{Y := (\<lambda>_. 1)}}\<^sub>g at B)
             {{Y := (\<lambda>_. 0)}}\<^sub>g at A)
             {{X := (\<lambda>s. val s X + 2 * d)}}\<^sub>g at A)
             {{X := (\<lambda>_. 0)}}\<^sub>g at A) \<or>\<^sub>g
     wait_cg
      (merge_inv (single_inv A (\<lambda>s0 t s. s = upd s0 X t))
                 (single_inv B (\<lambda>s0 t s. s = upd s0 Y 2)))
      B (\<lambda>_. 2) (\<lambda>d. (((sync_gassn {ch1, ch2} {A} {B}
             (single_assn A (ex2a_c n1))
             (single_assn B (ex2b_c n2))
             {{Y := (\<lambda>_. 2)}}\<^sub>g at B)
             {{Y := (\<lambda>_. 0)}}\<^sub>g at A)
             {{X := (\<lambda>s. val s X + d)}}\<^sub>g at A)
             {{X := (\<lambda>_. 0)}}\<^sub>g at A))) s0 \<Longrightarrow>\<^sub>G
    (wait_inv_cg (\<lambda>gs. valg gs A X \<in> {0..2})
       (\<lambda>s0 s tr. \<exists>s'. valg s' A X = 2 \<and>
         sync_gassn {ch1, ch2} {A} {B}
            (single_assn A (ex2a_c n1))
            (single_assn B (ex2b_c n2)) s' s tr)) s0"
  apply (rule entails_g_disj)
  subgoal
    (* Left branch *)
    apply (rule entails_g_trans)
     apply (rule wait_inv_cgI[where d=1 and J="\<lambda>gs. valg gs A X \<in> {0..2}"])
       apply (simp only: valg_def[symmetric]) apply auto[1]
    subgoal using assms ex_inv1 by blast
    apply (rule wait_inv_cg_mono)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (simp only: valg_def[symmetric]) apply auto
    unfolding entails_g_def apply auto
    subgoal for s tr
      apply (rule exI[where x="updg (updg (updg (updg s0 A X 0) A X 2) A Y 0) B Y 1"])
      apply (intro conjI)
      subgoal by (auto simp add: X_def Y_def A_def B_def)
      subgoal by auto
      done
    done
  subgoal
    (* Right branch *)
    apply (rule entails_g_trans)
     apply (rule wait_inv_cgI[where d=2 and J="\<lambda>gs. valg gs A X \<in> {0..2}"])
       apply (simp only: valg_def[symmetric]) apply auto[1]
    subgoal using assms ex_inv2 by blast
    apply (rule wait_inv_cg_mono)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (rule entails_g_trans)
     apply (rule gassn_subst)
    apply (simp only: valg_def[symmetric])
    unfolding entails_g_def apply auto
    subgoal for s tr
      apply (rule exI[where x="updg (updg (updg (updg s0 A X 0) A X 2) A Y 0) B Y 2"])
      apply (intro conjI)
      subgoal by (auto simp add: X_def Y_def A_def B_def)
      subgoal by auto
      done
    done
  done

fun ex2_c :: "nat \<Rightarrow> 'a gassn2" where
  "ex2_c 0 = init_single {A, B}"
| "ex2_c (Suc n) =
    (wait_inv_cg (\<lambda>gs. valg gs A X \<in> {0..2})
       (\<lambda>s0 s tr. \<exists>s'. valg s' A X = 2 \<and> ex2_c n s' s tr))"

lemma ex2''':
  "proc_set s0 = {A, B} \<Longrightarrow>
   (sync_gassn {ch1, ch2} {A} {B}
     (single_assn A (ex2a_c n1))
     (single_assn B (ex2b_c n2)) s0 \<Longrightarrow>\<^sub>G
   ex2_c n1 s0)"
proof (induction n1 n2 arbitrary: s0 rule: diff_induct)
  case (1 n1)
  show ?case
  proof (induction n1)
    case 0
    show ?case
      apply (auto simp add: single_assn_init)
      apply (rule sync_gassn_emp)
      by auto
  next
    case (Suc n1)
    show ?case
      apply (auto simp add: single_assn_simps)
      apply (rule sync_gassn_disj)
      subgoal apply (rule sync_gassn_outv_emp_unpair) by auto
      subgoal apply (rule sync_gassn_outv_emp_unpair) by auto
      done
  qed
next
  case (2 n2)
  show ?case
    apply (auto simp add: single_assn_simps)
    apply (rule sync_gassn_emp_in_unpair) by auto
next
  case (3 n1 n2)
  show ?case
    apply (rule entails_g_trans)
     apply (rule ex2')
    apply (rule entails_g_trans)
     apply (rule ex2'') apply (rule 3(2))
    apply simp
    apply (rule wait_inv_cg_mono)
    unfolding entails_g_def apply auto
    subgoal premises pre for s tr s'
    proof -
      have "proc_set_gassn {A, B}
        (sync_gassn {ch1, ch2} {A} {B} (single_assn A (ex2a_c n1))
                    (single_assn B (ex2b_c n2)))"
        by auto
      then have s': "proc_set s' = {A, B}"
        unfolding proc_set_gassn_def using pre(2) by blast
      show ?thesis
      apply (rule exI[where x=s'])
      apply auto
        using 3(1)[unfolded entails_g_def, OF s']
        using pre by auto
    qed
    done
qed

lemma ex2'''':
  "spec_of_global
    (Parallel (Single A ex2a)
              {ch1, ch2}
              (Single B ex2b))
    (\<exists>\<^sub>gn1 n2. sync_gassn {ch1, ch2} {A} {B}
                (single_assn A (ex2a_c n1))
                (single_assn B (ex2b_c n2)))"
  (* Stage 1: merge ex2a_c and ex2b_c *)
  apply (rule spec_of_global_post)
   apply (rule spec_of_parallel)
      apply (rule spec_of_single[OF ex2a_sp])
     apply (rule spec_of_single[OF ex2b_sp])
    apply auto   
  apply (auto simp add: single_assn_exists sync_gassn_exists_left)
  apply (auto simp add: sync_gassn_exists_right)
  by (rule entails_g_triv)

lemma ex2:
  "spec_of_global
    (Parallel (Single A ex2a)
              {ch1, ch2}
              (Single B ex2b))
   (\<exists>\<^sub>gn. ex2_c n)"
  apply (rule spec_of_global_post)
   apply (rule ex2'''') apply clarify
  apply (rule exists_gassn_elim)
  apply (rule exists_gassn_elim)
  subgoal premises pre for s0 n1 n2
    apply (rule exists_gassn_intro)
    apply (rule exI[where x=n1])
    apply (rule ex2''')
    using pre by auto
  done

end
