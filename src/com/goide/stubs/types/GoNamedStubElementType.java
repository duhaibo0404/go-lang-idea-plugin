/*
 * Copyright 2013-2014 Sergey Ignatov, Alexander Zolotov
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

package com.goide.stubs.types;

import com.goide.psi.GoNamedElement;
import com.goide.stubs.index.GoAllNamesIndex;
import com.intellij.lang.ASTNode;
import com.intellij.psi.PsiElement;
import com.intellij.psi.stubs.IndexSink;
import com.intellij.psi.stubs.NamedStubBase;
import com.intellij.psi.stubs.StubIndexKey;
import org.jetbrains.annotations.NonNls;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.generate.tostring.util.StringUtil;

import java.util.Collection;
import java.util.Collections;

public abstract class GoNamedStubElementType<S extends NamedStubBase<T>, T extends GoNamedElement> extends GoStubElementType<S, T> {
  public GoNamedStubElementType(@NonNls @NotNull String debugName) {
    super(debugName);
  }

  @Override
  public boolean shouldCreateStub(@NotNull ASTNode node) {
    PsiElement psi = node.getPsi();
    return psi instanceof GoNamedElement && StringUtil.isNotEmpty(((GoNamedElement)psi).getName());
  }

  public void indexStub(@NotNull final S stub, @NotNull final IndexSink sink) {
    String name = stub.getName();
    if (shouldIndex() && StringUtil.isNotEmpty(name)) {
      //noinspection ConstantConditions
      sink.occurrence(GoAllNamesIndex.ALL_NAMES, name);
      for (StubIndexKey<String, ? extends GoNamedElement> key : getExtraIndexKeys()) {
        sink.occurrence(key, name);
      }
    }
  }

  protected boolean shouldIndex() {
    return true;
  }

  @NotNull
  protected Collection<StubIndexKey<String, ? extends GoNamedElement>> getExtraIndexKeys() {
    return Collections.emptyList();
  }
}