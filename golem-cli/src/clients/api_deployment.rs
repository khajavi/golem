// Copyright 2024 Golem Cloud
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

use crate::model::{ApiDefinitionId, ApiDefinitionIdWithVersion, ApiDeployment, GolemError};
use async_trait::async_trait;

#[async_trait]
pub trait ApiDeploymentClient {
    type ProjectContext;

    async fn deploy(
        &self,
        api_definitions: Vec<ApiDefinitionIdWithVersion>,
        host: &str,
        subdomain: Option<String>,
        project: &Self::ProjectContext,
    ) -> Result<ApiDeployment, GolemError>;
    async fn list(
        &self,
        api_definition_id: &ApiDefinitionId,
        project: &Self::ProjectContext,
    ) -> Result<Vec<ApiDeployment>, GolemError>;
    async fn get(&self, site: &str) -> Result<ApiDeployment, GolemError>;
    async fn delete(&self, site: &str) -> Result<String, GolemError>;
}
