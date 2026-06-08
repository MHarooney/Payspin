import { Injectable } from '@nestjs/common';
import { SchemaMetadata, SchemaModelDto, SchemaRelationDto, SchemaFieldDto } from '@payspin/shared-types';
import { Prisma } from '@prisma/client';

@Injectable()
export class GetSchemaUseCase {
  execute(): SchemaMetadata {
    const dmmfModels = Prisma.dmmf.datamodel.models;

    const models: SchemaModelDto[] = dmmfModels.map((m) => {
      const scalarFields: SchemaFieldDto[] = m.fields
        .filter((f) => f.kind === 'scalar' || f.kind === 'enum')
        .map((f) => ({
          name: f.name,
          type: f.type,
          isRequired: f.isRequired,
          isList: f.isList,
          isRelation: false,
        }));

      const relationFields: SchemaFieldDto[] = m.fields
        .filter((f) => f.kind === 'object')
        .map((f) => ({
          name: f.name,
          type: f.type,
          isRequired: f.isRequired,
          isList: f.isList,
          isRelation: true,
          relationName: f.relationName ?? undefined,
          relationTarget: f.type,
        }));

      return {
        name: m.name,
        dbTable: m.dbName ?? m.name,
        fields: [...scalarFields, ...relationFields],
      };
    });

    const seenRelations = new Set<string>();
    const relations: SchemaRelationDto[] = [];

    for (const m of dmmfModels) {
      for (const f of m.fields) {
        if (f.kind !== 'object' || !f.relationName) continue;
        if (seenRelations.has(f.relationName)) continue;
        seenRelations.add(f.relationName);

        const reverseModel = dmmfModels.find((rm) => rm.name === f.type);
        const reverseField = reverseModel?.fields.find(
          (rf) => rf.relationName === f.relationName && rf.type === m.name,
        );

        let kind: SchemaRelationDto['kind'];
        if (!f.isList && reverseField && !reverseField.isList) {
          kind = 'one-to-one';
        } else if (!f.isList && reverseField?.isList) {
          kind = 'many-to-one';
        } else if (f.isList && reverseField && !reverseField.isList) {
          kind = 'one-to-many';
        } else {
          kind = 'many-to-many';
        }

        relations.push({ name: f.relationName, from: m.name, to: f.type, kind });
      }
    }

    return { models, relations };
  }
}
