/*
 * Copyright 2013-2016 Sergey Ignatov, Alexander Zolotov, Florin Patan
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// This is a generated file. Not intended for manual editing.
package com.goide.psi;

import java.util.List;
import org.jetbrains.annotations.*;
import com.intellij.psi.PsiElement;

public interface GoRecvStatement extends GoVarSpec {

  @NotNull
  List<GoExpression> getExpressionList();

  @NotNull
  List<GoVarDefinition> getVarDefinitionList();

  @Nullable
  PsiElement getVarAssign();

  @Nullable
  GoExpression getRecvExpression();

  @NotNull
  List<GoExpression> getLeftExpressionsList();

  @NotNull
  List<GoExpression> getRightExpressionsList();

}
